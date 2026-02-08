import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

async function main() {
  await prisma.ad.createMany({
    data: [
      {
        title: "Kahve %20 indirim",
        imageUrl: null,
        linkUrl: "https://example.com",
        city: "istanbul",
        isActive: true,
      },
      {
        title: "Happy hour 1+1",
        imageUrl: null,
        linkUrl: "https://example.com",
        city: "istanbul",
        isActive: true,
      },
    ],
    skipDuplicates: true,
  });

  // Demo user
  const user = await prisma.user.upsert({
    where: { phoneE164: "+900000000000" },
    update: {},
    create: { phoneE164: "+900000000000", nickname: "demo", deviceId: "demo" },
  });

  // Demo poll
  const poll = await prisma.poll.create({
    data: {
      question: "İstanbul'da en iyi manzara nerede?",
      options: { create: [{ text: "Galata" }, { text: "Üsküdar" }, { text: "Karaköy" }] },
    },
  });

  await prisma.post.createMany({
    data: [
      {
        userId: user.id,
        type: "text",
        text: "Kadıköy'de bugün trafik çok yoğun.",
        lat: 40.9901,
        lng: 29.0286,
        score: 12,
        commentCount: 1,
      },
      {
        userId: user.id,
        type: "photo",
        text: "Gün batımı 🔥",
        lat: 41.0430,
        lng: 29.0094,
        score: 5,
        commentCount: 0,
      },
      {
        userId: user.id,
        type: "poll",
        pollId: poll.id,
        lat: 41.0369,
        lng: 28.9850,
        score: 20,
        commentCount: 4,
      },
    ],
  });
}

main()
  .then(() => prisma.$disconnect())
  .catch((e) => {
    console.error(e);
    return prisma.$disconnect().finally(() => process.exit(1));
  });
