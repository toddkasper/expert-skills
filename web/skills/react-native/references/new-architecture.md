# New Architecture & Store Requirements — React Native / Expo

> Loaded on demand from the React Native skill body. Sections here are linked with explicit load cues.

---

## EAS Update

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

---

## New Architecture — JSI, Fabric, TurboModules

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

## Custom Native Modules

Under the New Architecture, native modules are **TurboModules** — they expose a C++ spec to JS via JSI and are loaded lazily (only when first called, reducing startup cost).

When you need custom native code:
1. First, look for an Expo module via `expo-modules-core` — it generates the JSI bindings from a Swift/Kotlin API surface automatically
2. If writing a TurboModule directly, define a TypeScript spec file (`NativeMyModule.ts` with `TurboModuleRegistry.getEnforcing`); codegen generates the C++/Java/ObjC glue
3. Legacy "Native Modules" using the bridge (`NativeModules.MyModule`) still work in SDK 52-54 but will break in future versions — do not write new code against the old bridge

**Red flag:** calling native module methods synchronously from the JS thread in a hot path. JSI calls are synchronous but still cross the JS-to-C++ boundary — batch calls and avoid per-frame native calls.

---

## App Store Requirements

All items below are volatile — verify against current platform policy before each submission. `[volatile — verify live]`

- **iOS:** requires building with the iOS 26 SDK or later (Apple updated this requirement for apps submitted from April 2026). Privacy manifest required (`PrivacyInfo.xcprivacy`). Account deletion flow required if the app has account creation. AI transparency disclosure required if the app uses external AI services.
- **Android:** target API level must meet Google Play's current minimum — verify the floor at the [Google Play target API level requirement](https://support.google.com/googleplay/android-developer/answer/11917455). The floor advances annually.
