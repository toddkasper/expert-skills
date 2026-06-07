# React Native + Expo — Study Resources

Load-on-demand companion to [../SKILL.md](../SKILL.md). Use when planning a learning path or looking up reference material for React Native and Expo development.

---

## Official Documentation

- [React Native — Core Components and APIs](https://reactnative.dev/docs/components-and-apis) — authoritative list of all built-in components; read before reaching for third-party libs
- [React Native — Performance](https://reactnative.dev/docs/performance) — JS thread vs UI thread framing, FlatList gotchas, animation best practices; essential for any performance work
- [React Native — New Architecture](https://reactnative.dev/architecture/landing-page) — JSI, Fabric, TurboModules; required reading for any native module or migration work
- [Expo Documentation — Workflow Overview](https://docs.expo.dev/workflow/overview/) — managed (CNG) vs bare workflow, how prebuild works
- [Expo Documentation — EAS Build](https://docs.expo.dev/build/introduction/) — cloud builds, credentials management, internal distribution
- [Expo Documentation — EAS Submit](https://docs.expo.dev/submit/introduction/) — automated store submission for iOS and Android
- [Expo Documentation — EAS Update](https://docs.expo.dev/eas-update/introduction/) — OTA updates, runtime versions, channels and branches
- [Expo Documentation — Permissions](https://docs.expo.dev/guides/permissions/) — two-step build-time + runtime pattern, config plugins, platform gotchas
- [Expo Router — Introduction](https://docs.expo.dev/router/introduction/) — file-based routing, typed routes, deep linking
- [Expo Router — Navigation](https://docs.expo.dev/router/basics/navigation/) — stack, tabs, drawers in the file-system model
- [Expo Changelog — SDK 56 Beta](https://expo.dev/changelog/sdk-56-beta) — tracks latest SDK changes including Jetpack Compose and SwiftUI stable APIs

## Key Third-Party Libraries (Official Sites)

- [React Navigation](https://reactnavigation.org/) — imperative navigation library; use directly for bare-workflow or complex custom navigation scenarios
- [React Native Reanimated](https://docs.swmansion.com/react-native-reanimated/) — worklet-based animation running on the UI thread; the standard for production animations
- [React Native Gesture Handler](https://docs.swmansion.com/react-native-gesture-handler/) — native-driven gesture recognition; required by React Navigation
- [FlashList](https://shopify.github.io/flash-list/) — Shopify's high-performance list component; faster than FlatList for long lists with known item types
- [React Native Directory](https://reactnative.directory/) — community library index with New Architecture compatibility flags; check here before adding any dependency

## App Store Submission References

- [Apple Developer Program](https://developer.apple.com/programs/) — $99 USD/year required for iOS distribution; check current requirements before submitting
- [Google Play Console Help](https://support.google.com/googleplay/android-developer) — $25 USD one-time fee; Google Service Account Key required for EAS Submit automation
- [Expo — App Credentials](https://docs.expo.dev/app-signing/app-credentials/) — how EAS manages keystores and provisioning profiles

---

_Independent educational content. React Native is a trademark of Meta; Expo is a trademark of Expo. Not affiliated with or endorsed by either._
