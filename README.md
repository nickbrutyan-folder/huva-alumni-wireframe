# HUVA Academy — Alumni Page (Wireframe)

Single-page directory of HUVA Academy graduates. Production-grade chrome matched to the live [huva.io](https://huva.io) (real header SVG, glassmorphic nav, sticky yellow CTA, black footer).

Live: https://nickbrutyan-folder.github.io/huva-alumni-wireframe/

## What's here

- `index.html` — the whole page (data-driven; alumni live in a JS array near the bottom)
- `avatars/` — 50 real Instagram profile pictures (320×320 HD), pre-fetched locally
- `fetch-avatars.sh` — re-runnable script to refresh the avatars (IG CDN URLs expire)

## Data model

Each alumni entry:
```js
{ name, handle, url, platform, bio, courses: ["academy-pro", "academy", "creator"] }
```

`bio` is the better of the form-submitted pitch and the Instagram bio (human-curated).

## Refresh avatars

```bash
./fetch-avatars.sh
```

Uses Instagram's `og:image` (via `facebookexternalhit` UA) and falls back to the `web_profile_info` JSON endpoint for HD. ~50/54 handles resolve; the remaining 4 are private accounts.

For maximum reliability + HD photos, the avatars in this commit were pulled via the Apify `instagram-profile-scraper` actor.
