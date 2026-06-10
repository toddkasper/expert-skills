---
name: react-native
description: Building and reviewing React Native and Expo mobile apps — core components and styling (Flexbox, FlatList), navigation (Expo Router, React Navigation), the Expo SDK and permissions, native modules and the New Architecture (JSI, Fabric, TurboModules), EAS Build/Submit/Update, iOS/Android platform differences, and mobile performance. Use when building, reviewing, or debugging RN/Expo apps or the native/mobile layer. Assumes core React (see react); covers the mobile deltas only. Competence skill — no first-party certification.
metadata:
  credential: None — competence skill (no first-party React Native / Expo certification)
  domain: web
  type: competence-playbook
  status: active
  last-reviewed: 2026-06-09
---

# React Native + Expo — Skills Reference

## Overview

React Native lets you build iOS and Android apps in JavaScript/TypeScript using a React component model, but the runtime, component set, and performance constraints differ fundamentally from the browser. This skill covers those deltas — what a strong React Native / Expo engineer knows that goes beyond React-on-the-web competence.

Key shifts from the web:
- No DOM, no CSS — layout is Flexbox-only via `StyleSheet`, components are `View`/`Text`/`Image`, not `div`/`span`/`img`
- Two threads that must stay unblocked — the JS thread and the UI/main thread; dropped frames come from overloading either
- New Architecture is mandatory — JSI replaces the async bridge; Fabric replaces the old renderer; TurboModules replace legacy native modules (default from RN 0.76+, mandatory from Expo SDK 55+) `[volatile — verify live]`
- Ship cycle is different — JS-only changes can be pushed OTA via EAS Update; anything touching native code requires a new store binary

> **Load this skill when…** building or reviewing a React Native or Expo mobile app; debugging dropped frames, list performance, or native module integration; working with EAS Build/Submit/Update or the New Architecture; handling iOS/Android platform differences or permissions.
> **Not this skill:** core React hooks, state, and testing patterns → see `react`; this skill covers mobile deltas only.

> **Deeper context:** Study resources live in [references/study-resources.md](references/study-resources.md). Load that file when looking up official docs or library links.

> **Verify steps assume nothing about your tooling** — use your project's own scripts and the language toolchain (`tsc`, `node`, the test runner, the package manager), in that order of preference.

---

## Uncertainty & Escalation

- **Always re-verify live:** Expo SDK versions and React Native releases change frequently — New Architecture defaults, SDK-required library minimum versions, and EAS Update behavior evolve each cycle. `[volatile — verify live]` marks apply to: New Architecture mandatory adoption (default RN 0.76+, mandatory Expo SDK 55+ — `[volatile — verify live]`, check `expo` version in `package.json`); Expo SDK version-specific library minimums (React Navigation, Reanimated, Gesture Handler version gates — `[volatile — verify live]`); `runtimeVersion` behavior for EAS Update (match semantics may change — `[volatile — verify live]`); iOS App Store SDK requirement (currently iOS 26 SDK from April 2026 — `[volatile — verify live]`, advances annually); Android target API level floor (`[volatile — verify live]`, check Google Play policy for current minimum). Always run `npx expo-doctor@latest` after any SDK upgrade to catch compatibility issues.
- **Live wins:** the installed Expo SDK / RN version's actual behavior, [docs.expo.dev](https://docs.expo.dev), and [reactnative.dev](https://reactnative.dev) are authoritative over this file → log discrepancies via Feedback protocol below.
- **Escalate to a human:** production store submissions (iOS App Store, Google Play); EAS Update pushes to a production channel (irreversible reach); major Expo SDK upgrades on a live app; Android keystore rotation or loss; permission message changes (require new binary — cannot be OTA'd).
- **Confidence taxonomy:** facts in this file are stable unless tagged `[volatile — verify live]` or `[opinion — house style]`.

---

## 1. RN Core — Components, Styling, Lists, and Platform Differences

### Components: no HTML, no DOM

| Web equivalent | React Native component | Notes |
|---|---|---|
| `<div>` | `<View>` | Layout container; Flexbox column by default |
| `<span>` / `<p>` | `<Text>` | All visible text must be inside `<Text>`; nesting `<Text>` inside `<View>` without wrapping in `<Text>` throws an error |
| `<img>` | `<Image>` | Requires explicit `width`/`height` or a flex layout; remote images need a `{ uri: '...' }` source |
| `<input>` | `<TextInput>` | No `onChange` — use `onChangeText`; `value` + `onChangeText` for controlled inputs |
| `<button>` | `<Pressable>` (preferred) or `<Button>` | `<Button>` is heavily platform-styled; `<Pressable>` with custom children for pixel-level control |
| `<div style={{ overflow: 'scroll' }}>` | `<ScrollView>` | Renders all children up front — do NOT use for long dynamic lists |
| Long dynamic list | `<FlatList>` | Virtualized — renders only visible items + a small buffer; requires `data` + `renderItem` + `keyExtractor` |
| Sectioned list | `<SectionList>` | Like `FlatList` but with section headers; data shape is `[{ title, data: [] }]` |

**Text nesting rule:** every string literal rendered to screen must be wrapped in `<Text>`. Rendering a bare string inside `<View>` is a runtime error on Android.

### Styling — Flexbox only

- `StyleSheet.create({ ... })` — pass objects through this; validates style keys in development and improves perf via style ID deduplication
- Default flex direction is **column** (not row, unlike the web default)
- No `%` widths in most contexts — use `flex: 1` to fill available space; use `Dimensions.get('window')` or the `useWindowDimensions` hook for pixel math
- No `em`/`rem` — use the `PixelRatio` API for density-aware sizing or rely on `Dimensions`
- `position: 'absolute'` works as expected; no `position: fixed` (use native modal or navigation header for sticky UI)

### FlatList — the mandatory performance knob

`FlatList` defers rendering of off-screen items. Key props:

| Prop | Why it matters |
|---|---|
| `keyExtractor` | Must return a unique stable string — missing or unstable keys cause full re-renders on data change |
| `getItemLayout` | Tells RN item size without measuring — skip this for variable-height items only; providing it enables instant scroll-to-index |
| `windowSize` | Controls how many screen-heights of items are pre-rendered (default 21); lower it for heavy items |
| `removeClippedSubviews` | Unmounts off-screen native views — effective on Android; can cause blank flashes on iOS if overused |
| `initialNumToRender` | Items rendered on first paint — set high enough to fill the screen, not higher |

**Red flag:** using `<ScrollView>` with a `.map()` for a list of unknown length. It renders all items immediately, causes layout jank, and can exhaust memory.

**FlashList alternative:** Shopify's FlashList is significantly faster than FlatList for homogeneous-item lists because it recycles item components. Use it for any list > ~100 items with a consistent item type. Requires New Architecture.

### Platform-specific code

```typescript
// Inline conditional
import { Platform } from 'react-native';
const hitSlop = Platform.OS === 'ios' ? { top: 10, bottom: 10 } : { top: 5, bottom: 5 };

// Platform-specific files (auto-selected at bundle time)
// MyComponent.ios.tsx  — used on iOS
// MyComponent.android.tsx  — used on Android
// MyComponent.tsx  — fallback
```

Key platform differences to remember:
- **Back button:** Android has a hardware back button; iOS does not. Use `BackHandler` (or React Navigation's built-in handling) to intercept it on Android
- **Safe area:** status bar, notch, and home indicator insets differ by device. Use `react-native-safe-area-context` (`SafeAreaView` from that library, not from RN core — the core `SafeAreaView` is deprecated)
- **Permissions model:** iOS asks once per permission category and stores the choice permanently; Android (M+) differentiates "normal" vs "dangerous" permissions and allows the user to revoke at any time
- **Keyboard:** `KeyboardAvoidingView` behavior differs by platform — use `behavior="padding"` on iOS and `behavior="height"` on Android, or test both and use `Platform.select`

---

## 2. Navigation — Expo Router and React Navigation

### Expo Router (file-based — preferred for new projects)

Expo Router is built on React Navigation internally but adds a file-system convention: every file in the `app/` directory becomes a route. No navigator registration, no manual type definitions.

```
app/
  _layout.tsx        — root layout, wraps everything (define Stack/Tabs here)
  index.tsx          — maps to "/"
  (tabs)/
    _layout.tsx      — tab bar definition
    home.tsx         — tab route
    profile.tsx      — tab route
  products/
    [id].tsx         — dynamic segment → accessible as useLocalSearchParams().id
```

**Stack, tab, and drawer in Expo Router:**
- `<Stack>` in `_layout.tsx` → stack navigator for that segment
- `<Tabs>` in `_layout.tsx` → bottom tab bar
- `<Drawer>` requires `expo-router/drawer` and Reanimated 3+

**Navigation calls:**
```typescript
import { router, Link } from 'expo-router';
router.push('/products/42');   // push onto stack
router.replace('/home');       // replace (no back)
router.back();                 // go back
<Link href="/profile">Profile</Link>  // declarative link
```

**Typed routes:** enable `experiments.typedRoutes: true` in `app.json` — the router then infers valid hrefs from the file system; broken links become TypeScript errors.

**Deep linking:** automatic — every route is a universal link/app link without extra configuration. Pass `scheme` in `app.json`; Expo CLI generates the entitlements/intent filters.

### React Navigation (imperative — for bare projects or complex custom navigators)

Use React Navigation directly when: you are not using Expo Router, you need a custom navigator type, or you need fine-grained control over the transition animations that Expo Router's file system abstraction doesn't expose.

Navigators: `createNativeStackNavigator` (native platform transitions, best performance), `createBottomTabNavigator`, `createDrawerNavigator`, `createMaterialTopTabNavigator`.

**`createNativeStackNavigator` vs `createStackNavigator`:** always prefer native stack — it delegates transitions to the OS's native navigation stack (UINavigationController on iOS, Fragment on Android), which runs on the UI thread and is unaffected by JS thread load. The JS stack is rendered in React and drops frames under heavy JS work.

**Red flags:**
- Using `createStackNavigator` (JS-based) when `createNativeStackNavigator` is available
- Performing data fetching or heavy computation synchronously in a screen component during a navigation transition — defer with `useEffect` + a loading state
- Forgetting `SafeAreaProvider` at the root — causes overlapping content on notched devices

---

## 3. Native Capabilities — Expo SDK, Permissions, and Native Modules

### Expo SDK modules

The Expo SDK is a set of libraries that expose native device capabilities with a consistent, cross-platform JavaScript API. Prefer Expo SDK modules over raw React Native APIs or arbitrary npm packages — they are maintained, integrate with EAS, and support config plugins for build-time configuration.

| Capability | Expo module |
|---|---|
| Camera | `expo-camera` |
| Image picker | `expo-image-picker` |
| Location | `expo-location` |
| Notifications (local + push) | `expo-notifications` |
| Secure key-value store | `expo-secure-store` |
| File system | `expo-file-system` |
| Tracking transparency (iOS) | `expo-tracking-transparency` |
| Media library | `expo-media-library` |

Check [React Native Directory](https://reactnative.directory/) for New Architecture compatibility before adding any non-Expo library.

### Permissions — the two-step pattern

**Build time:** permissions must be declared before they can be requested. In Expo managed workflow this happens automatically via config plugins when you add a library. For custom permissions or messages, configure in `app.json`:
```json
{
  "expo": {
    "android": { "permissions": ["android.permission.CAMERA"] },
    "ios": { "infoPlist": { "NSCameraUsageDescription": "Used to scan barcodes." } }
  }
}
```

**Runtime:** request with the library's API (e.g. `Camera.requestCameraPermissionsAsync()`). Always check status first — if `granted`, proceed; if `denied`, show a message directing users to Settings; if `undetermined`, request.

**Critical iOS gotcha:** permission messages in `Info.plist` cannot be updated over-the-air. Changing a usage description string requires a new native binary submission to the App Store. Plan permission messaging carefully before the first production release.

**Critical Android gotcha:** removing a permission that a library adds via its own manifest requires explicitly listing it in `android.blockedPermissions`. Without this, the permission remains in the merged manifest even if you remove the library.

**Custom native modules (TurboModules, expo-modules-core):** prefer `expo-modules-core` for new native code; it generates JSI bindings automatically from a Swift/Kotlin API. Do not write new code against the legacy `NativeModules.MyModule` bridge. Full TurboModule authoring guide: [references/new-architecture.md](references/new-architecture.md) → "Custom Native Modules."

---

## 4. Build, Ship, and EAS

### Managed workflow vs bare workflow

| | Managed (CNG) | Bare |
|---|---|---|
| `ios/` and `android/` directories | Generated on demand by `npx expo prebuild` | Committed to the repo |
| Upgrade path | Run prebuild again after updating; native config re-generated from `app.json` | Manual native file edits required for each upgrade |
| Config plugins | Apply automatically at prebuild | Apply automatically at prebuild; manual native edits also possible |
| When to use | Default for all new projects | Only when you need native changes that no config plugin can express |

**Decision rule:** start managed. Only commit `ios/` and `android/` (bare) if you have a concrete native change that cannot be expressed as a config plugin. Once you manually edit those directories you cannot safely re-run `npx expo prebuild` without overwriting your changes.

### EAS Build

EAS Build compiles and signs your app in the cloud. Key commands:
```bash
eas build --platform ios --profile production
eas build --platform android --profile production
eas build --platform all --profile preview   # internal distribution build
```

Profiles are defined in `eas.json`. Common profiles: `development` (creates a development client), `preview` (internal distribution, no store), `production` (store-ready, signed).

Credentials: EAS stores and manages your iOS provisioning profile + distribution certificate and your Android keystore. Use `eas credentials` to inspect or rotate them. **Never lose your Android keystore** — Google Play ties the app to the keystore; a lost keystore means you cannot update your Play Store listing.

### EAS Submit

```bash
eas submit --platform ios    # submits latest production build to App Store Connect
eas submit --platform android
```

Prerequisites:
- **iOS:** Apple Developer Program membership ($99 USD/year). App Store Connect API key configured in `eas.json` for automated submission.
- **Android:** Google Play Developer account ($25 USD one-time). Google Service Account Key with "Release manager" permission configured for automated submission.

**EAS Update (OTA):** pushes JS and asset changes without a store review. Cannot update native code, new permissions, or new native modules — those require a new binary. The `runtimeVersion` in `app.json` must match the binary; bump it whenever native-facing code changes. Full OTA update mechanics (channels/branches, `runtime-version` semantics, OTA can/cannot table, rollback steps): [references/new-architecture.md](references/new-architecture.md) → "EAS Update."

**App store requirements** (iOS SDK minimum, privacy manifest, account deletion requirement, Android target API floor) — all volatile `[verify live]`: [references/new-architecture.md](references/new-architecture.md) → "App Store Requirements."

---

## 5. New Architecture — JSI, Fabric, TurboModules

Mandatory from Expo SDK 55+ (cannot be disabled) `[volatile — verify live]`. JSI replaces the async bridge with direct C++ object references; Fabric enables synchronous layout measurement; TurboModules load lazily to improve cold-start. Always run `npx expo-doctor@latest` after adding dependencies to catch New Architecture incompatibilities. Legacy `NativeModules.X` bridge calls still work via interop in SDK 52-54 — plan migration before SDK 55.

> **Deep dive** (JSI/Fabric/TurboModules mechanics, full migration checklist, ecosystem library minimum versions): load [references/new-architecture.md](references/new-architecture.md).

---

## 6. Performance

### The two-thread model (memorize this)

| Thread | Runs | Blocked by |
|---|---|---|
| JS thread | React rendering, business logic, API calls, event handlers | Heavy computation, synchronous JS, large re-renders |
| UI thread (main) | Native layout, animations with `useNativeDriver: true`, scroll handling | Native layout recalculation, rendering too many views |

Dropped frames happen when either thread misses its 16.67ms (60 FPS) budget.

### Performance rules

**Animations:** always pass `useNativeDriver: true` to `Animated` API calls. This moves the animation interpolation to the UI thread; without it, every animation frame crosses to the JS thread and drops when JS is busy. Use `react-native-reanimated` for animations that need to react to gesture state — Reanimated worklets run entirely on the UI thread.

**Lists:** for lists with >50 items, provide `getItemLayout` to `FlatList` if items are fixed-height. For variable-height or very long lists (>200 items), consider FlashList. Never put `FlatList` inside a `ScrollView` with the same scroll axis — the outer scroll view disables virtualization.

**Images:** do not animate `width`/`height` — iOS re-crops from the original on every frame. Animate `transform: [{ scale }]` instead. For remote images, use `expo-image` (not the core `Image` component) — it has built-in memory and disk caching and BlurHash placeholder support.

**JS thread load:** defer expensive work after navigation transitions complete with `InteractionManager.runAfterInteractions`. Avoid inline arrow functions in `renderItem` — they create new function references on every render and prevent memoization.

**Startup:** remove all `console.log` statements from production bundles (use `babel-plugin-transform-remove-console`). Use `import()` lazy imports for heavy screens not in the critical path. TurboModules load lazily by default in the New Architecture — no extra work needed.

**Testing performance:** always profile in a release build, not development mode. Development mode enables runtime warnings and extra checks that add 5–10× overhead; perf numbers from dev mode are not representative.

### Common anti-patterns (red flags in review)

- `<ScrollView>` rendering a list of unknown length — use `FlatList`
- `FlatList` inside a `ScrollView` on the same axis — kills virtualization
- `Animated.Value` without `useNativeDriver: true` on a looping animation
- New `renderItem` function created per render (inline arrow) without `useCallback`
- `console.log` left in production code paths
- Calling `setState` inside an `onScroll` handler that fires at 60 FPS — debounce or use native event handlers
- Loading a full-resolution camera roll photo for a thumbnail — request a specific size via `expo-image-picker`'s `quality` and `width`/`height` options

---

## Executable Workflows

### Workflow 1 — Ship an OTA update safely (match runtimeVersion → EAS Update → verify reach, know what needs a new build)

1. Before publishing, confirm the change is OTA-safe: JS/TS logic changes, React component updates, and bundled asset changes are OTA-safe. Any change to native modules, `ios/` or `android/` directories, `Info.plist` values, `AndroidManifest.xml` permissions, or Expo SDK modules with native code requires a new binary. → gate: run `git diff --name-only HEAD~1` — if any file under `ios/`, `android/`, or `app.json`'s `plugins`/`android`/`ios` arrays changed, this update needs a new build.
2. Confirm the `runtimeVersion` in `app.json` matches the production binary. If native code changed since the last binary, bump `runtimeVersion` first and publish a new binary before sending an update. → gate: `eas build:list` shows the production channel build's runtime version equals `app.json`'s `runtimeVersion`.
3. Publish the update: `eas update --branch production --message "description of change"`. → gate: the command completes without errors and prints an update ID.
4. Monitor rollout: `eas update:list --branch production` shows the new update. Check Expo Dashboard for "reached" count — allow 15–30 min for users to pick up the update on app foreground. → gate: reached count is growing; no new crash reports in the monitoring tool.
5. If a bad update ships, immediately publish a rollback: republish the previous known-good JS bundle (`eas update --branch production --message "rollback" --republish --group <previous-group-id>`). Do not wait for a new binary for JS-level bugs.

### Workflow 2 — Add a native permission (config plugin → request flow → rebuild)

1. Install the Expo SDK module that requires the permission (e.g., `npx expo install expo-camera`). The module's config plugin auto-adds the required entries to `Info.plist` and `AndroidManifest.xml` at prebuild time. → gate: check `app.json`'s `plugins` array — the module should be listed (some auto-register, some require explicit addition).
2. For custom permission messages (required on iOS), add to `app.json`: `"ios": { "infoPlist": { "NSCameraUsageDescription": "Used to scan barcodes." } }`. iOS will reject App Store submissions without descriptive usage strings. → gate: the string is present in `app.json`; it is descriptive (not "needed for the app").
3. Run `npx expo prebuild --clean` to regenerate native directories from the updated `app.json`. → gate: `ios/YourApp/Info.plist` contains the usage description key; `android/app/src/main/AndroidManifest.xml` contains the permission.
4. Build a new binary: `eas build --platform all --profile preview` (for testing) or `--profile production`. This step is mandatory — permission changes cannot be shipped OTA. → gate: build completes; install on a physical device (not simulator) to test permission prompts.
5. In the JS code, request the permission at the appropriate moment (before first use, not at app launch). Handle all three status outcomes: `granted` → proceed; `denied` → show a message with a button to `Linking.openSettings()`; `undetermined` → call the request API. → gate: on a fresh install, the system permission dialog appears at the correct moment; denying it shows the in-app guidance without a crash.

### Workflow 3 — Optimize a long list (FlatList/FlashList: keyExtractor, getItemLayout, windowSize)

1. Identify whether items are homogeneous (same component type, same approximate height) or heterogeneous. Homogeneous lists > ~100 items: use FlashList (`@shopify/flash-list`). Heterogeneous or shorter lists: use FlatList. → gate: FlashList requires New Architecture (SDK 55+ has it mandatory — verify).
2. Provide `keyExtractor` returning a unique stable string from the item's data (e.g., `item.id.toString()`), never the array index. → gate: change the data order in state; confirm no unexpected component unmounting/remounting in React DevTools.
3. If all items have the same height, provide `getItemLayout`: `(_, index) => ({ length: ITEM_HEIGHT, offset: ITEM_HEIGHT * index, index })`. This enables instant `scrollToIndex` and removes layout-measuring overhead. → gate: `flatListRef.current.scrollToIndex({ index: 50 })` completes without "cannot scroll to index" warning.
4. Tune `windowSize` (default 21 — 10 screens above + 10 below + 1 visible). For heavy items (images, complex layouts), lower to 5–11 to reduce memory. For fast-scroll lists, keep it higher. → gate: profile in a release build with Hermes; JS thread stays under 16ms per frame while scrolling.
5. Extract `renderItem` to a stable function outside the render body or use `useCallback`. Wrap the item component in `React.memo`. → gate: React DevTools Profiler shows items that leave the viewport as "Did not render" when parent state changes unrelated to the list data.

---

## Decision Scenarios

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

Further scenario (expo-image vs core Image for remote-image caching): [references/scenarios.md](references/scenarios.md).

---

## Operational Rules Quick Reference

- **DO** wrap all visible strings in `<Text>` — a bare string inside `<View>` is a runtime error on Android
- **DON'T** use `<ScrollView>` for long or dynamic lists — use `<FlatList>` (virtualized)
- **DO** use `<Pressable>` instead of `<TouchableOpacity>` for new touch targets — it is the current recommended primitive
- **DON'T** use the deprecated `SafeAreaView` from `react-native` — use `react-native-safe-area-context`
- **DO** provide `keyExtractor` returning a unique stable string to every `FlatList`
- **DO** prefer `createNativeStackNavigator` over `createStackNavigator` — native stack runs on the UI thread
- **DO** start with Expo managed workflow (CNG); only commit native directories when a config plugin cannot cover the requirement
- **DON'T** assume an EAS Update can deliver new native modules or new permissions — those require a new store binary
- **DO** bump the EAS Update runtime version whenever native-facing code changes
- **DO** check React Native Directory for New Architecture compatibility before adding any dependency (mandatory from SDK 55+)
- **DON'T** write new native modules against the legacy bridge (`NativeModules.X`) — use `expo-modules-core` or a TurboModule spec
- **DO** use `useNativeDriver: true` on all `Animated` API calls; use Reanimated for gesture-driven animations
- **DON'T** animate `width`/`height` on images — animate `transform: [{ scale }]` instead
- **DO** test performance in release builds, not dev mode
- **DON'T** put DML-equivalent work (data fetching, heavy computation) synchronously in a component rendered during a navigation transition
- **DO** plan iOS permission messages before the first production release — they cannot be changed OTA
- **DON'T** lose the Android keystore — it is tied to the Play Store listing and unrecoverable
- **DO** verify library compatibility with `npx expo-doctor@latest` before upgrading Expo SDK versions

---

## Feedback protocol

Using this skill and hit a wall? If you find a claim contradicted by the live system or official docs, a missing rule that cost you a wrong attempt, or a decision this skill gave no criteria for — append an entry **in the moment** to `.skill-feedback/react-native.md` at the project root (create it if absent):

`date | skill last-reviewed | claim or gap | what you observed instead | evidence (error text / doc URL / query output) | suggested fix`

These are harvested back into the skill via the learning loop. When the live system and this file disagree, trust the live system.

## Changelog

- **2026-06-09** — Conformed to the 12-dimension skill standard: task-vocab description + Scope block, Uncertainty & Escalation guidance with inline `[volatile — verify live]` marks, executable workflows, tool-agnostic verify steps, and the feedback protocol above. `last-reviewed` set to 2026-06-09.
- **2026-06-09** — Curation pass (inbox: D9 audit finding): inlined 3 decision scenarios into the body (Scenarios 2–4: managed-workflow prebuild overwrite, FlashList/New Architecture compatibility, InteractionManager for transition jank) to meet the teaching-scenario standard (≥4 inline). Scenario 5 remains in references. Section 5 (New Architecture), native modules/JSI subsection, and App store requirements moved to references/new-architecture.md to offset body length.

---

_Independent educational content to upskill AI agents. React Native is a trademark of Meta; Expo is a trademark of Expo. Not affiliated with or endorsed by either. Guidance only — verify against official documentation before acting._
