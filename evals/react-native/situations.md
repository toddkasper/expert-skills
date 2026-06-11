# Eval situations — react-native (held-out set, 2026-06-07)

> _Held-out eval content — original, not exam material (no real exam questions; see POLICY.md). Do not paste into a skill body._

Answer each: state the **competent action** and the **reason**. Be concise (2–4 sentences each).

1. A React Native app renders a list of 500 chat messages. The current implementation uses a `<ScrollView>` with a `.map()` that renders each message as a `<View>` containing two `<Text>` components. Users report the message screen takes 3–4 seconds to load and scrolling is janky. A teammate suggests adding `React.memo` to the message component. What is the actual root cause, and what is the correct structural fix?

2. A team ships an EAS Update to fix a login crash that affected all users on the `production` channel. The update is published and the branch is linked to the channel. Two days later, 30% of affected users are still reporting the crash. The JavaScript fix is verified correct. What is the most likely reason a portion of users are not receiving the update, and what should you check?

3. You are reviewing a PR that adds camera functionality to an Expo managed-workflow app. The developer has added `expo-camera` to `package.json`, added the `NSCameraUsageDescription` string to `app.json`'s `ios.infoPlist`, and calls `Camera.requestCameraPermissionsAsync()` at runtime before opening the camera. The PR looks complete. What critical step is missing that will cause the feature to silently fail or crash in production, and why does it work fine in Expo Go?

4. A navigation screen takes noticeably long to appear after a user taps a list item. Profiling reveals the screen component immediately on mount runs a synchronous loop over 50,000 items to compute an initial sort order, completing in ~200ms. The project uses `createNativeStackNavigator`. A developer proposes switching to `createStackNavigator` to see if the transition is smoother. Is that the right fix? What is actually causing the delay, and what is the correct approach?

5. An animation on iOS looks silky-smooth in development but drops frames in the production release build. The animation is implemented with the `Animated` API and `useNativeDriver` is set to `true`. After investigating, a developer notices the animation drives a `width` change on an `<Image>` component. What is the root cause of the frame drops and what is the correct fix?

6. Your app has been live on Google Play for 18 months. The developer who originally set up the project has left the company, and IT cannot locate the Android keystore file used for signing the production build. Leadership wants to push an urgent bug fix. What are the consequences, and what is the only viable path forward?

7. A product manager asks you to push a hotfix that adds a new required runtime permission (`ACCESS_FINE_LOCATION`) to the Android app. The fix is needed immediately and they want to use EAS Update to avoid a week-long store review. Can you do this with an OTA update? What must happen instead, and what is the technical reason?

8. An app built on Expo SDK 54 has a third-party library `react-native-fancy-charts` (no Expo SDK wrapper). The team plans to upgrade to SDK 55. Running `npx expo-doctor@latest` reports `react-native-fancy-charts` has no New Architecture support. A developer argues it will still work because it functioned fine under SDK 54. What is the risk in SDK 55 specifically, and what should the team do before upgrading?

9. A `FlatList` renders user profile cards. Each card has a fixed height of 120 dp. When a user taps "Jump to member #3000" the app calls `flatListRef.current.scrollToIndex({ index: 3000 })` and immediately throws a warning: "scrollToIndex should be used in conjunction with getItemLayout." The list has 5,000 items and `getItemLayout` is not provided. What must you add, what is the exact function signature, and what happens if item heights are variable?

10. A developer uses `KeyboardAvoidingView` to prevent the keyboard from covering a message input field. On iOS the input lifts correctly. On Android the input is either over-shifted or doesn't move at all. The `behavior` prop is set to `"padding"`. What is the platform-specific fix, and why does a single `behavior` value not work correctly on both platforms?

11. An Expo managed-workflow app stores sensitive authentication tokens using `AsyncStorage` from `@react-native-async-storage/async-storage`. A security audit flags this as a vulnerability. What storage mechanism should replace it, and what is the specific risk that `AsyncStorage` introduces on both iOS and Android?

12. A new team member adds a bare string literal directly inside a `<View>` to display a loading message on Android: `<View>{isLoading && "Loading..."}</View>`. The component renders correctly in iOS simulator. The Android QA engineer reports the app hard-crashes on that screen. What is the cause, the correct fix, and why does it not crash on iOS?

13. A team has been running Expo SDK 55 in production for three months. Their animation library is `react-native-reanimated@3.16.0`. After an unrelated dependency update the animations begin failing with cryptic JSI errors. A developer proposes pinning back to `3.14.0` to restore stability. What is the actual root cause of the failures, and what is the correct resolution?

14. A startup's React Native app runs on Expo SDK 54. The engineering lead has heard that "New Architecture migration is optional for now" and decides to defer it indefinitely while shipping new features on SDK 55. They upgrade to SDK 55 without auditing their third-party libraries for New Architecture compatibility. What actually happens on first launch, and what should the team have done before upgrading?

15. A developer starts a new project on Expo SDK 55 and installs `@shopify/flash-list` for a contacts list of ~2,000 items. They copy a code example from a tutorial that includes `estimatedItemSize={80}`. The app runs without error but the console shows a deprecation warning stating `estimatedItemSize` is no longer used. The developer asks if they should remove it or keep it for "backwards compatibility." What should they do, and what underlying architectural change made the prop unnecessary?
