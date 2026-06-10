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

### Native modules and JSI (when Expo SDK is not enough)

Under the New Architecture, native modules are **TurboModules** — they expose a C++ spec to JS via JSI and are loaded lazily (only when first called, reducing startup cost).

When you need custom native code:
1. First, look for an Expo module via `expo-modules-core` — it generates the JSI bindings from a Swift/Kotlin API surface automatically
2. If writing a TurboModule directly, define a TypeScript spec file (`NativeMyModule.ts` with `TurboModuleRegistry.getEnforcing`); codegen generates the C++/Java/ObjC glue
3. Legacy "Native Modules" using the bridge (`NativeModules.MyModule`) still work in SDK 52-54 but will break in future versions — do not write new code against the old bridge

**Red flag:** calling native module methods synchronously from the JS thread in a hot path. JSI calls are synchronous but still cross the JS-to-C++ boundary — batch calls and avoid per-frame native calls.

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

### EAS Update — OTA updates

EAS Update pushes JavaScript and asset changes to users without a store review. It cannot update native code (anything in `ios/` or `android/`), new permissions, or new native modules.

**Runtime version:** a label that identifies the JS-native interface contract of a build. When native code changes in a way that affects the JS API surface, bump the runtime version in `app.json`. Updates are only delivered to builds whose runtime version exactly matches.

**Channels and branches:** a build is assigned a channel (e.g. `production`, `staging`). A channel is linked to a branch. Publishing an update pushes to a branch; all builds on the linked channel receive it.

```bash
eas update --branch production --message "Fix login crash"
```

**What OTA can and cannot update:**

| Can update OTA | Cannot update OTA |
|---|---|
| JavaScript/TypeScript logic | Native modules (new or changed) |
| React component tree | Permissions (Info.plist / AndroidManifest) |
| Assets bundled at build time | App icons, splash screen |
| Expo SDK version (JS side only) | SDK upgrades that change native code |

**Red flag:** assuming an EAS Update can deliver a new native module, a new permission, or a new Expo SDK module that has native code. That requires a new build + store submission.

### App store requirements (as of 2026)

- **iOS:** requires building with the iOS 26 SDK or later (Apple updated this requirement for apps submitted from April 2026) `[volatile — verify live]`. Privacy manifest required. Account deletion required if the app has account creation. AI transparency disclosure required if the app uses external AI services.
- **Android:** target API level must meet Google Play's minimum (verify the current floor at Google Play policy — it advances annually).

---

## 5. New Architecture — JSI, Fabric, TurboModules

The New Architecture is the default from React Native 0.76+ and mandatory from Expo SDK 55+ (cannot be disabled). `[volatile — verify live]`

### The three components

**JSI (JavaScript Interface):** replaces the async serialization bridge. JS holds a direct C++ reference to native objects and can call methods synchronously without JSON serialization. This eliminates the queuing latency and the copy overhead that made the old bridge a bottleneck.

**Fabric:** the new renderer. It runs the React shadow tree calculation in C++ (on any thread) and can perform synchronous layout measurement — enabling Reanimated's `measure()` and React 18 concurrent features. The old renderer was JS-only and required a full async round-trip to measure views.

**TurboModules:** native modules built on JSI. They load lazily (only when first accessed) rather than at startup. For apps with many native modules, this alone improves cold-start time measurably.

### Migration checklist for existing projects

1. Run `npx expo-doctor@latest` — it flags libraries incompatible with the New Architecture
2. Check [React Native Directory](https://reactnative.directory/) for the `new arch` badge on every dependency
3. Major ecosystem libraries that require minimum versions: React Navigation 7.2+, Reanimated 3.5.1+, Gesture Handler 2.16.2+, Vision Camera 4.0+
4. Legacy bridge modules (`NativeModules.X`) still work via interop in SDK 52-54; plan migration before SDK 55

**Red flag:** adding a library without checking its New Architecture support status — it may cause silent runtime failures or a hard crash rather than a clean error.

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

Further scenarios: [references/scenarios.md](references/scenarios.md)

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

---

_Independent educational content to upskill AI agents. React Native is a trademark of Meta; Expo is a trademark of Expo. Not affiliated with or endorsed by either. Guidance only — verify against official documentation before acting._
