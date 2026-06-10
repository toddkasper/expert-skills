# Trigger tests — react-native (Lens 2)

Routing regression set. Test each phrasing against skill DESCRIPTIONS only. Each routes to exactly one skill.

## Should route to react-native  (5)

1. "Our Expo app's FlatList is janky when scrolling 500 items — we're using a ScrollView with a map and React.memo didn't help"
2. "We shipped an OTA update via EAS Update to fix a bug but it added a new runtime permission — users are getting permission crashes"
3. "The iOS build works but Android crashes with 'Invariant Violation: Text strings must be rendered within a <Text> component' on a screen that renders fine in iOS simulator"
4. "We can't find the Android keystore that signed our production app — how do we push an urgent update?"
5. "Our Animated API animation is smooth in dev but drops frames in the production release build even though `useNativeDriver: true` is set"

## Near-misses → a sibling  (4)

1. "My React component list re-renders too often — I want to memoize the items" → `react`  (a web React memoization concern; no mobile/Expo-specific component or FlatList involved)
2. "We're building a Next.js app and want to cache the product list between navigations without re-fetching" → `nextjs`  (a Next.js App Router caching concern, not a React Native / mobile concern)
3. "Our TypeScript types for our navigation stack are getting complex — how do I type the params correctly with React Navigation?" → `react-native`  (navigation typing IS a React Native / React Navigation concern — routes here, not `typescript`, because it's about the RN navigation framework's type patterns)
4. "I have a React `useEffect` that sets up an interval and I need to clean it up when the component unmounts" → `react`  (pure React lifecycle / cleanup pattern; no mobile platform concern)
