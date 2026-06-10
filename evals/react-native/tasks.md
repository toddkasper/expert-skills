# Application tasks — react-native (Lens 4, held-out)

A skilled agent produces the artifact; a judge grades against the trap-keyed rubric. Run baseline vs skilled.

## Task 1 — Redline this screen for list performance and OTA/native change flaws

**Prompt to the agent:** Review the following React Native screen and produce a written redline identifying every list-rendering, OTA-compatibility, permission-flow, and cleanup flaw. For each flaw, name the exact problem, explain the risk, and prescribe the fix.

```tsx
import React, { useState, useEffect } from 'react';
import { ScrollView, View, Text, TouchableOpacity } from 'react-native';
import * as Contacts from 'expo-contacts';

export default function ContactsScreen() {
  const [contacts, setContacts] = useState<any[]>([]);
  const [granted, setGranted] = useState(false);

  useEffect(() => {
    (async () => {
      const data = await Contacts.getContactsAsync();
      setContacts(data.data);
    })();
  }, []);

  const requestAndLoad = async () => {
    const { status } = await Contacts.requestPermissionsAsync();
    setGranted(status === 'granted');
    if (status === 'granted') {
      const data = await Contacts.getContactsAsync();
      setContacts(data.data);
    }
  };

  return (
    <ScrollView>
      {!granted && (
        <TouchableOpacity onPress={requestAndLoad}>
          <Text>Load Contacts</Text>
        </TouchableOpacity>
      )}
      {contacts.map((c, index) => (
        <View key={index}>
          <Text>{c.name}</Text>
        </View>
      ))}
    </ScrollView>
  );
}
```

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — `ScrollView` + `.map()` for a potentially large contact list: `ScrollView` renders all items at once; a user with 1,000+ contacts will experience severe load time and memory pressure; fix is `FlatList` with `keyExtractor` and `renderItem`.
- [ ] Trap 2 — `Contacts.getContactsAsync()` called in `useEffect` without checking permission first: the app reads contacts without user consent; on iOS this will silently return empty data after first denial; on Android 6+ it throws a permissions error; fix is to call `Contacts.requestPermissionsAsync()` (or `Contacts.getPermissionsAsync()` to check existing grant) before any data access.
- [ ] Trap 3 — `key={index}` on the contact list: if contacts are filtered, sorted, or paginated, index keys cause React Native to reuse `View`/`Text` nodes incorrectly; fix is `key={c.id}` using the contact's stable identifier.
- [ ] Trap 4 — Inline arrow function as the `ScrollView` child map callback (and in the eventual `FlatList` `renderItem`): defining `renderItem={() => <ContactRow ... />}` inline recreates the function every render, defeating `FlatList`'s cell recycling optimization; fix is to extract `renderItem` as a `useCallback` or a stable function reference outside the component.
- [ ] Trap 5 — `expo-contacts` requires a native module rebuild: adding `expo-contacts` to a managed Expo workflow project requires running a new EAS Build (it adds native code); it cannot be shipped as an OTA update via EAS Update; teams that try to push this as a JS-only update will crash on devices that received the OTA without the native binary; fix is to always create a new native build when adding or upgrading packages with native dependencies.
- [ ] No new errors introduced

**Reference — a competent artifact:**
- Replaces `ScrollView` + `.map()` with `FlatList` and shows `keyExtractor` and `renderItem` props.
- Identifies the permissions-before-data-access flaw specifically and distinguishes iOS silent-empty vs Android-throw behavior.
- Explains why `key={index}` is unsafe for dynamic lists and prescribes stable IDs.
- Names the inline `renderItem` recreation problem and prescribes `useCallback` or a stable function.
- Explains the OTA-vs-native-module distinction for `expo-contacts` and names the consequence of shipping it as an OTA-only update.
- Does not introduce new issues (e.g., does not suggest `VirtualizedList` directly or remove the permission flow entirely).

---

## Task 2 — Redline this navigation screen for performance, platform, and cleanup flaws

**Prompt to the agent:** Review the following React Native screen used in a `createNativeStackNavigator` app and produce a written redline identifying every performance, platform-difference, and effect-cleanup flaw. For each flaw, name the exact problem, explain the risk, and prescribe the fix.

```tsx
import React, { useState, useEffect } from 'react';
import { View, Text, FlatList, KeyboardAvoidingView, TextInput } from 'react-native';
import { useNavigation } from '@react-navigation/native';

const ITEMS = Array.from({ length: 10000 }, (_, i) => ({ id: String(i), label: `Item ${i}` }));

export default function SearchScreen() {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState(ITEMS);
  const navigation = useNavigation();

  useEffect(() => {
    // Filter synchronously on every keystroke
    const filtered = ITEMS.filter(item =>
      item.label.toLowerCase().includes(query.toLowerCase())
    );
    setResults(filtered);
  }, [query]);

  useEffect(() => {
    const sub = navigation.addListener('focus', () => {
      console.log('Screen focused');
    });
    // no cleanup
  }, [navigation]);

  return (
    <KeyboardAvoidingView behavior="padding">
      <TextInput
        value={query}
        onChangeText={setQuery}
        placeholder="Search..."
      />
      <FlatList
        data={results}
        renderItem={({ item }) => <Text>{item.label}</Text>}
        keyExtractor={item => item.id}
      />
    </KeyboardAvoidingView>
  );
}
```

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — Synchronous filter of 10,000 items inside `useEffect` on every keystroke: this blocks the JS thread on each character typed, causing input lag and dropped frames; fix is to move the filter to a `useMemo` (computed during render, not an effect) and optionally debounce the query value to reduce computation frequency.
- [ ] Trap 2 — Deriving `results` via `useEffect` + `setResults` instead of `useMemo`: using an effect to set derived state creates an extra render cycle (render with stale results → effect fires → render again with new results); filtering is pure computation and belongs in `useMemo` or a plain variable, not an effect.
- [ ] Trap 3 — `navigation.addListener('focus', ...)` without returning the cleanup/unsubscribe function: the listener is never removed; each time the screen remounts (e.g., due to navigation stack changes), a new listener is registered on top of the old one, causing the callback to fire multiple times and leaking memory; fix is `return sub;` inside the `useEffect`.
- [ ] Trap 4 — `KeyboardAvoidingView behavior="padding"` on Android: on Android the correct behavior is `"height"` (or relying on `android:windowSoftInputMode="adjustResize"` in the manifest); `"padding"` works on iOS but over-shifts or has no effect on Android; fix is `behavior={Platform.OS === 'ios' ? 'padding' : 'height'}`.
- [ ] Trap 5 — Inline `renderItem` arrow function `({ item }) => <Text>{item.label}</Text>`: defining `renderItem` inline means a new function reference is created on every render of `SearchScreen`, which defeats `FlatList`'s cell-reuse optimization (cells are considered "different" and re-rendered); fix is `useCallback` with appropriate dependencies or extracting to a stable component outside the screen.
- [ ] No new errors introduced

**Reference — a competent artifact:**
- Replaces the `useEffect` filter with `useMemo` and explains both the extra-render-cycle flaw and the JS-thread-blocking flaw.
- Identifies the missing cleanup on the navigation listener and shows the `return sub` pattern.
- Names the `KeyboardAvoidingView` platform-behavior mismatch and prescribes `Platform.OS` branching.
- Identifies the inline `renderItem` as a FlatList optimization killer and prescribes `useCallback` or stable extraction.
- Does not introduce new issues (e.g., does not suggest replacing `FlatList` with `VirtualizedList` for simple fixed-height lists, or removing `useNativeDriver` from unrelated animations).
