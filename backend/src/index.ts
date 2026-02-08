import Fastify from "fastify";
import cors from "@fastify/cors";
import multipart from "@fastify/multipart";
import rateLimit from "@fastify/rate-limit";
import swagger from "@fastify/swagger";
import swaggerUI from "@fastify/swagger-ui";
import { z } from "zod";
import jwt from "jsonwebtoken";
import Redis from "ioredis";
import { PrismaClient, PostType, Prisma } from "@prisma/client";
import { randomUUID } from "crypto";
import fs from "fs";
import path from "path";
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";

const prisma = new PrismaClient();
const redis = new Redis(process.env.REDIS_URL || "redis://localhost:6379");

const app = Fastify({ logger: true });

process.on("unhandledRejection", (err) => {
  app.log.error({ err }, "unhandledRejection");
});
process.on("uncaughtException", (err) => {
  app.log.error({ err }, "uncaughtException");
});

await app.register(cors, { origin: true });
await app.register(multipart);
await app.register(rateLimit, {
  max: Number(process.env.RATE_LIMIT_MAX || 60),
  timeWindow: Number(process.env.RATE_LIMIT_TIME_WINDOW || 60000),
});
await app.register(swagger, {
  swagger: {
    info: { title: "Spotted API", version: "0.1.0" },
  },
});
await app.register(swaggerUI, { routePrefix: "/docs" });

const JWT_SECRET = process.env.JWT_SECRET || "dev-secret";
const OTP_TTL = Number(process.env.OTP_TTL_SECONDS || 300);
const MEDIA_STORAGE = process.env.MEDIA_STORAGE || "local";
const MEDIA_LOCAL_PATH = process.env.MEDIA_LOCAL_PATH || "./uploads";
const REPORT_HIDE_THRESHOLD = Number(process.env.REPORT_HIDE_THRESHOLD || 20);
const LOCATION_GRID_METERS = Number(process.env.LOCATION_GRID_METERS || 1000);
const MEDIA_MAX_BYTES = Number(process.env.MEDIA_MAX_BYTES || 5 * 1024 * 1024);
const MEDIA_ALLOWED_MIME = new Set(
  (process.env.MEDIA_ALLOWED_MIME || "image/jpeg,image/png,image/webp")
    .split(",")
    .map((s) => s.trim())
);
const CACHE_CONTROL = "public, max-age=31536000, immutable";

const s3 = new S3Client({
  region: process.env.SPACES_REGION || "fra1",
  endpoint: process.env.SPACES_ENDPOINT,
  credentials: process.env.SPACES_ACCESS_KEY && process.env.SPACES_SECRET_KEY
    ? {
        accessKeyId: process.env.SPACES_ACCESS_KEY,
        secretAccessKey: process.env.SPACES_SECRET_KEY,
      }
    : undefined,
});

function signToken(userId: string) {
  return jwt.sign({ sub: userId }, JWT_SECRET, { expiresIn: "30d" });
}

const ALLOW_ANON = process.env.ALLOW_ANON !== "false";
const DEV_PHONE = "+900000000000";
const DEV_DEVICE_ID = "dev-device";

async function getDevUserId() {
  const user = await prisma.user.upsert({
    where: { phoneE164: DEV_PHONE },
    update: { deviceId: DEV_DEVICE_ID, nickname: "dev" },
    create: { phoneE164: DEV_PHONE, nickname: "dev", deviceId: DEV_DEVICE_ID },
  });
  return user.id;
}

async function auth(req: any) {
  const header = req.headers.authorization || "";
  const token = header.replace("Bearer ", "");
  if (token) {
    try {
      const payload = jwt.verify(token, JWT_SECRET) as { sub: string };
      return payload.sub;
    } catch {
      if (!ALLOW_ANON) throw new Error("unauthorized");
    }
  }
  if (ALLOW_ANON) {
    return await getDevUserId();
  }
  throw new Error("unauthorized");
}

function snapLatLng(lat: number, lng: number) {
  if (!LOCATION_GRID_METERS || LOCATION_GRID_METERS <= 0) return { lat, lng };
  const latStep = LOCATION_GRID_METERS / 111_320;
  const lngStep = LOCATION_GRID_METERS / (111_320 * Math.cos((lat * Math.PI) / 180));
  return {
    lat: Math.round(lat / latStep) * latStep,
    lng: Math.round(lng / lngStep) * lngStep,
  };
}

app.get("/health", async () => ({ ok: true }));

app.post("/auth/otp/request", async (req, reply) => {
  const body = z.object({ phoneE164: z.string() }).parse(req.body);
  const requestId = randomUUID();
  const code = "123456"; // TODO: real SMS
  await redis.setex(`otp:${requestId}`, OTP_TTL, JSON.stringify({ phone: body.phoneE164, code }));
  return reply.send({ requestId });
});

app.post("/auth/otp/verify", async (req, reply) => {
  const body = z.object({ requestId: z.string(), code: z.string(), deviceId: z.string() }).parse(req.body);
  const raw = await redis.get(`otp:${body.requestId}`);
  if (!raw) return reply.code(400).send({ code: "otp_expired", message: "OTP expired" });
  const data = JSON.parse(raw) as { phone: string; code: string };
  if (data.code !== body.code) return reply.code(400).send({ code: "otp_invalid", message: "Invalid OTP" });

  const user = await prisma.user.upsert({
    where: { phoneE164: data.phone },
    update: { deviceId: body.deviceId },
    create: { phoneE164: data.phone, nickname: "anon", deviceId: body.deviceId },
  });

  const token = signToken(user.id);
  return reply.send({ accessToken: token, userId: user.id, needsNickname: user.nickname === "anon" });
});

app.post("/profile", async (req, reply) => {
  const userId = await auth(req);
  const body = z.object({ nickname: z.string().min(2) }).parse(req.body);
  await prisma.user.update({ where: { id: userId }, data: { nickname: body.nickname } });
  return reply.send({ ok: true });
});

app.get("/feed", async (req, reply) => {
  const q = z.object({
    lat: z.coerce.number(),
    lng: z.coerce.number(),
    radius_km: z.coerce.number(),
    cursor: z.string().optional(),
  }).parse(req.query);

  const limit = 20;
  const cursor = q.cursor ? new Date(q.cursor) : undefined;
  const snapped = snapLatLng(q.lat, q.lng);

  const latParam = Prisma.sql`${snapped.lat}::double precision`;
  const lngParam = Prisma.sql`${snapped.lng}::double precision`;
  const radiusParam = Prisma.sql`${q.radius_km}::double precision`;

  const baseSql = Prisma.sql`
    SELECT * FROM "Post"
    WHERE "isHidden" = false
      AND ("expiresAt" IS NULL OR "expiresAt" > NOW())
      AND (
        6371 * acos(
          cos(radians(${latParam})) * cos(radians("lat")) * cos(radians("lng") - radians(${lngParam})) +
          sin(radians(${latParam})) * sin(radians("lat"))
        )
      ) <= ${radiusParam}
  `;

  const withCursor = cursor
    ? Prisma.sql`${baseSql} AND "createdAt" < ${cursor}::timestamptz ORDER BY "createdAt" DESC LIMIT ${limit}`
    : Prisma.sql`${baseSql} ORDER BY "createdAt" DESC LIMIT ${limit}`;

  const rows = await prisma.$queryRaw<{ id: string }[]>(Prisma.sql`SELECT "id" FROM (${withCursor}) AS "PostIds"`);
  const ids = rows.map((row) => row.id);
  const postsRaw = ids.length
    ? await prisma.post.findMany({
        where: { id: { in: ids } },
        include: { poll: { include: { options: true } } },
      })
    : [];
  const byId = new Map(postsRaw.map((post) => [post.id, post]));
  const posts = ids.map((id) => byId.get(id)).filter(Boolean) as typeof postsRaw;

  const nextCursor = posts.length === limit ? posts[posts.length - 1].createdAt.toISOString() : null;

  const ad = await prisma.ad.findFirst({ where: { isActive: true, city: "istanbul" } });
  return reply.send({ posts, ad, nextCursor });
});

app.get("/posts/:id", async (req, reply) => {
  const params = z.object({ id: z.string() }).parse(req.params);
  const post = await prisma.post.findUnique({ where: { id: params.id }, include: { poll: { include: { options: true } } } });
  if (!post) return reply.code(404).send({ code: "not_found" });

  const comments = await prisma.comment.findMany({ where: { postId: params.id }, orderBy: { createdAt: "desc" }, take: 50 });
  return reply.send({ post, comments, nextCursor: null });
});

app.post("/posts", async (req, reply) => {
  const userId = await auth(req);
  const body = z.object({
    type: z.nativeEnum(PostType),
    text: z.string().optional().nullable(),
    photoURL: z.string().optional().nullable(),
    linkURL: z.string().optional().nullable(),
    poll: z.object({ question: z.string(), options: z.array(z.string()) }).optional().nullable(),
    lat: z.number(),
    lng: z.number(),
  }).parse(req.body);

  const snapped = snapLatLng(body.lat, body.lng);

  let pollId: string | null = null;
  if (body.poll) {
    const poll = await prisma.poll.create({ data: { question: body.poll.question, options: { create: body.poll.options.map((t) => ({ text: t })) } } });
    pollId = poll.id;
  }

  const post = await prisma.post.create({
    data: {
      userId,
      type: body.type,
      text: body.text || undefined,
      photoUrl: body.photoURL || undefined,
      linkUrl: body.linkURL || undefined,
      pollId,
      lat: snapped.lat,
      lng: snapped.lng,
      expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
    },
  });

  return reply.send({ id: post.id });
});

app.post("/posts/:id/comments", async (req, reply) => {
  const userId = await auth(req);
  const params = z.object({ id: z.string() }).parse(req.params);
  const body = z.object({ text: z.string().min(1) }).parse(req.body);

  await prisma.comment.create({ data: { postId: params.id, userId, text: body.text } });
  await prisma.post.update({ where: { id: params.id }, data: { commentCount: { increment: 1 } } });

  return reply.send({ ok: true });
});

app.post("/posts/:id/vote", async (req, reply) => {
  const userId = await auth(req);
  const params = z.object({ id: z.string() }).parse(req.params);
  const body = z.object({ value: z.number().int().min(-1).max(1) }).parse(req.body);

  const existing = await prisma.vote.findUnique({ where: { postId_userId: { postId: params.id, userId } } });
  if (existing) {
    await prisma.vote.update({ where: { id: existing.id }, data: { value: body.value } });
  } else {
    await prisma.vote.create({ data: { postId: params.id, userId, value: body.value } });
  }
  await prisma.post.update({ where: { id: params.id }, data: { score: { increment: body.value } } });

  return reply.send({ ok: true });
});

app.delete("/posts/:id/vote", async (req, reply) => {
  const userId = await auth(req);
  const params = z.object({ id: z.string() }).parse(req.params);
  const existing = await prisma.vote.findUnique({ where: { postId_userId: { postId: params.id, userId } } });
  if (existing) {
    await prisma.vote.delete({ where: { id: existing.id } });
    await prisma.post.update({ where: { id: params.id }, data: { score: { decrement: existing.value } } });
  }
  return reply.send({ ok: true });
});

app.post("/reports", async (req, reply) => {
  const userId = await auth(req);
  const body = z.object({ postId: z.string(), reason: z.string().min(1) }).parse(req.body);
  await prisma.report.create({ data: { postId: body.postId, userId, reason: body.reason } });
  const count = await prisma.report.count({ where: { postId: body.postId } });
  if (count >= REPORT_HIDE_THRESHOLD) {
    await prisma.post.update({ where: { id: body.postId }, data: { isHidden: true } });
  }
  return reply.send({ ok: true });
});

app.post("/polls/:id/vote", async (req, reply) => {
  const userId = await auth(req);
  const params = z.object({ id: z.string() }).parse(req.params);
  const body = z.object({ optionId: z.string() }).parse(req.body);

  const option = await prisma.pollOption.findUnique({ where: { id: body.optionId } });
  if (!option || option.pollId !== params.id) {
    return reply.code(400).send({ code: "invalid_option" });
  }

  const existing = await prisma.pollVote.findUnique({ where: { pollId_userId: { pollId: params.id, userId } } });
  if (existing) {
    await prisma.pollVote.update({ where: { id: existing.id }, data: { optionId: body.optionId } });
  } else {
    await prisma.pollVote.create({ data: { pollId: params.id, optionId: body.optionId, userId } });
  }

  return reply.send({ ok: true });
});

app.get("/ads/next", async (req, reply) => {
  const q = z.object({ city: z.string().optional() }).parse(req.query);
  const ad = await prisma.ad.findFirst({
    where: { isActive: true, city: q.city || "istanbul" },
    orderBy: { createdAt: "desc" },
  });
  return reply.send(ad);
});

app.get("/ads", async (req, reply) => {
  await auth(req);
  const ads = await prisma.ad.findMany({ orderBy: { createdAt: "desc" } });
  return reply.send(ads);
});

app.post("/ads", async (req, reply) => {
  await auth(req);
  const body = z.object({
    title: z.string(),
    imageUrl: z.string().optional().nullable(),
    linkUrl: z.string(),
    city: z.string(),
    isActive: z.boolean().optional(),
  }).parse(req.body);
  const ad = await prisma.ad.create({ data: body });
  return reply.send(ad);
});

app.patch("/ads/:id", async (req, reply) => {
  await auth(req);
  const params = z.object({ id: z.string() }).parse(req.params);
  const body = z.object({
    title: z.string().optional(),
    imageUrl: z.string().optional().nullable(),
    linkUrl: z.string().optional(),
    city: z.string().optional(),
    isActive: z.boolean().optional(),
  }).parse(req.body);
  const ad = await prisma.ad.update({ where: { id: params.id }, data: body });
  return reply.send(ad);
});

app.post("/media/upload", async (req, reply) => {
  const parts = await req.file();
  if (!parts) return reply.code(400).send({ code: "no_file" });
  if (!MEDIA_ALLOWED_MIME.has(parts.mimetype)) {
    return reply.code(400).send({ code: "invalid_type" });
  }

  if (MEDIA_STORAGE === "spaces") {
    const bucket = process.env.SPACES_BUCKET || "";
    const publicBase = process.env.SPACES_PUBLIC_BASE_URL || "";
    const key = `${randomUUID()}-${parts.filename}`;

    const buffer = await parts.toBuffer();
    if (buffer.length > MEDIA_MAX_BYTES) {
      return reply.code(400).send({ code: "file_too_large" });
    }
    await s3.send(new PutObjectCommand({
      Bucket: bucket,
      Key: key,
      Body: buffer,
      ContentType: parts.mimetype,
      ACL: "public-read",
      CacheControl: CACHE_CONTROL,
    }));

    reply.header("Cache-Control", CACHE_CONTROL);
    return reply.send({ url: `${publicBase}/${key}` });
  }

  if (!fs.existsSync(MEDIA_LOCAL_PATH)) fs.mkdirSync(MEDIA_LOCAL_PATH, { recursive: true });
  const filename = `${randomUUID()}-${parts.filename}`;
  const filepath = path.join(MEDIA_LOCAL_PATH, filename);
  const buffer = await parts.toBuffer();
  if (buffer.length > MEDIA_MAX_BYTES) {
    return reply.code(400).send({ code: "file_too_large" });
  }
  fs.writeFileSync(filepath, buffer);

  reply.header("Cache-Control", CACHE_CONTROL);
  return reply.send({ url: `local://${filename}` });
});

app.post("/push/register", async (req, reply) => {
  const userId = await auth(req);
  const body = z.object({
    token: z.string(),
    platform: z.enum(["ios", "android"]).default("ios"),
  }).parse(req.body);

  await prisma.deviceToken.upsert({
    where: { token: body.token },
    update: { userId, platform: body.platform },
    create: { userId, token: body.token, platform: body.platform },
  });

  return reply.send({ ok: true });
});

app.listen({ port: Number(process.env.PORT || 3000), host: "0.0.0.0" });
