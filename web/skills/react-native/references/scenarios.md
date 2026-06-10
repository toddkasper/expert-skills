# React Native — Decision Scenarios

**Scenario 1 — Inline arrow in `renderItem` defeats `React.memo` on list items**

> **Situation:** A developer wraps a `ProductCard` list item in `React.memo` to prevent re-renders when the parent's state changes. Profiling still shows every `ProductCard` re-rendering whenever the parent updates. The `FlatList` is defined as `renderItem={({ item }) => <ProductCard product={item} onPress={() => handlePress(item.id)} />}`.

> **Competent move:** Extract `renderItem` to a stable function outside the render body (or use `useCallback`), and ensure the `onPress` callback reference is stable (e.g., accepts `item.id` as a parameter rather than closing over a new arrow per item). `React.memo` compares props by reference — a new inline arrow function is a new reference on every render, so the `memo` check always fails.

> **Tempting-but-wrong:** Increasing `windowSize` or lowering `initialNumToRender` to reduce the number of re-renders at the cost of blank flashes. Tuning FlatList window props does not fix the root cause (unstable `renderItem` reference) — it just reduces how many items are in the window at once.

> **Verify:** Use React DevTools Profiler (Hermes mode or Flipper) to confirm which prop triggered the re-render. After stabilizing `renderItem`, the profiler should show "Did not render" for off-screen items when unrelated parent state changes.

---

**Scenario 2 — Manually edited `ios/` files are overwritten by `npx expo prebuild`**

> **Situation:** A developer in a managed-workflow Expo app adds custom iOS entitlements by directly editing `ios/MyApp.entitlements`. Three weeks later a teammate runs `npx expo prebuild --clean` during an SDK upgrade. The entitlements file is regenerated from `app.json` and the custom entries are silently lost, breaking push notification capabilities in the next store submission.

> **Competent move:** Encode the entitlements in a config plugin instead of editing the native file directly. Config plugins transform `app.json` into the correct native file contents on every prebuild run, so changes survive upgrades. Committing manually edited `ios/` files and re-running `--clean` prebuild are fundamentally incompatible — the `--clean` flag is designed to regenerate from scratch.

> **Tempting-but-wrong:** Committing the edited `ios/` directory and documenting "never run `prebuild --clean`." This couples the team to a fragile, undocumented constraint. The next developer or CI pipeline that follows standard upgrade procedures will lose the changes without warning.

> **Verify:** Write the config plugin to add the entitlements entry. Run `npx expo prebuild --clean` and inspect the generated `ios/MyApp.entitlements`. Confirm the custom entry is present — the plugin is working. Remove the manually edited version from version control.

---

**Scenario 3 — FlashList used without verifying New Architecture compatibility**

> **Situation:** A team on Expo SDK 54 adds Shopify's `FlashList` to replace `FlatList` on a heavy 1,000-item list. It works well. They upgrade to Expo SDK 55 (New Architecture mandatory) and the app crashes on launch with a native module error.

> **Competent move:** Before upgrading to SDK 55, check `FlashList`'s New Architecture compatibility status on React Native Directory and verify the installed version meets the minimum required. Run `npx expo-doctor@latest` after adding any new dependency to catch NA incompatibility before attempting the SDK upgrade. Update `FlashList` to a NA-compatible version before upgrading the SDK.

> **Tempting-but-wrong:** Disabling the New Architecture in SDK 55 to unblock the team. The New Architecture cannot be disabled in Expo SDK 55+ — it is mandatory. The only forward path is to bring every native dependency into NA compliance.

> **Verify:** Run `npx expo-doctor@latest` with the target SDK version and confirm no "New Architecture incompatible" warnings. Build a development client (`eas build --profile development`) and smoke-test the list on a physical device before shipping.

---

**Scenario 4 — Heavy data processing on screen mount blocks the navigation transition animation**

> **Situation:** A "Report" screen computes a statistics summary by synchronously iterating over 10,000 records immediately on component mount (outside any effect, in the component body). Users see the navigation transition stutter before the screen appears. A developer moves the computation into `useEffect([])` but the jank persists.

> **Competent move:** Wrap the computation call in `InteractionManager.runAfterInteractions(() => { /* compute */ })`. Navigation transitions are driven by the JS thread — any synchronous work running on the JS thread during the transition competes with the animation interpolation and causes dropped frames. `InteractionManager.runAfterInteractions` defers the callback until all active navigation interactions have completed, allowing the transition to finish at full frame rate before the heavy work starts.

> **Tempting-but-wrong:** Moving the computation into `useEffect([])`. A `useEffect` runs after the first render commit, but the render commit itself happens during the navigation transition — the computation still executes while the transition animation is in flight.

> **Verify:** Record a slow-motion video of the transition using iOS Simulator's slow animations (`⌘T`) or Android GPU profiler before and after adding `InteractionManager`. After the fix, the transition should complete smoothly before the statistics appear (possibly with a brief loading indicator).

---

**Scenario 5 — Using core `<Image>` for a remote-image grid causes visible flicker on re-renders**

> **Situation:** A photo gallery screen uses the built-in `<Image>` component to display 48 thumbnails loaded from remote URLs. On Android, scrolling back to already-viewed items causes visible white flicker as images reload. On iOS the caching is slightly better but BlurHash placeholders are not supported.

> **Competent move:** Replace the core `<Image>` with `<Image>` from `expo-image`. `expo-image` has built-in memory and disk caching, meaning previously loaded images are served from cache without a network round-trip. It also supports `placeholder` with BlurHash/ThumbHash for smooth loading UX. The core `<Image>` has no caching layer — every render that triggers an image load hits the network or at best the OS cache.

> **Tempting-but-wrong:** Adding a manual `Cache-Control` header to the image server and assuming the OS HTTP cache handles re-display. HTTP caching reduces network requests but does not prevent the decode-and-paint cost on re-render, which causes the flicker. `expo-image` caches the decoded bitmap in memory for instant re-display.

> **Verify:** Install `expo-image`, replace the `Image` import, and scroll back and forth through the gallery. With `expo-image`, previously loaded thumbnails should appear instantly with no white frame. Monitor memory usage to confirm caching does not grow unboundedly (expo-image has a configurable cache size).
