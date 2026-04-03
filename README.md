# chessiq

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Deploy To Netlify

This repo is configured for Netlify with:

- `netlify.toml`
- `netlify-build.sh`
- `web/_redirects`

### One-time setup

1. Push this project to GitHub.
2. In Netlify, choose **Add new site** -> **Import an existing project**.
3. Select your GitHub repo.
4. Netlify will detect `netlify.toml` automatically.
5. Trigger deploy.

### Notes

- Build command: `bash netlify-build.sh`
- Publish directory: `build/web`
- Redirect rule in `web/_redirects` ensures SPA routes load correctly.
