# Spotted Backend

## Quick start

```bash
cp .env.example .env
# start infra
Docker compose up -d
# install deps
npm install
# prisma
npx prisma generate
npx prisma migrate dev --name init
# run
npm run dev
```

Swagger docs: `http://localhost:3000/docs`

## Notes

- OTP is mocked (code: `123456`).
- Media upload supports local or DigitalOcean Spaces.
- Push is only device token registration (no APNs sender yet).

## Env

- `MEDIA_STORAGE=local|spaces`
- `SPACES_*` vars for DO Spaces
- `REPORT_HIDE_THRESHOLD` for auto-hide
- `LOCATION_GRID_METERS` for location privacy
- `MEDIA_MAX_BYTES` and `MEDIA_ALLOWED_MIME` for upload validation

## TODO (next)

- APNs sender
- Moderation panel
- SMS OTP provider
- CI/CD pipeline
