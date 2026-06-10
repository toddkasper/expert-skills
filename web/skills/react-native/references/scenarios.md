# React Native — Decision Scenarios

Scenarios 1–4 have been inlined into the SKILL.md body. This file holds Scenario 5 only.

---

**Scenario 5 — Using core `<Image>` for a remote-image grid causes visible flicker on re-renders**

> **Situation:** A photo gallery screen uses the built-in `<Image>` component to display 48 thumbnails loaded from remote URLs. On Android, scrolling back to already-viewed items causes visible white flicker as images reload. On iOS the caching is slightly better but BlurHash placeholders are not supported.

> **Competent move:** Replace the core `<Image>` with `<Image>` from `expo-image`. `expo-image` has built-in memory and disk caching, meaning previously loaded images are served from cache without a network round-trip. It also supports `placeholder` with BlurHash/ThumbHash for smooth loading UX. The core `<Image>` has no caching layer — every render that triggers an image load hits the network or at best the OS cache.

> **Tempting-but-wrong:** Adding a manual `Cache-Control` header to the image server and assuming the OS HTTP cache handles re-display. HTTP caching reduces network requests but does not prevent the decode-and-paint cost on re-render, which causes the flicker. `expo-image` caches the decoded bitmap in memory for instant re-display.

> **Verify:** Install `expo-image`, replace the `Image` import, and scroll back and forth through the gallery. With `expo-image`, previously loaded thumbnails should appear instantly with no white frame. Monitor memory usage to confirm caching does not grow unboundedly (expo-image has a configurable cache size).
