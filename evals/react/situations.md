# Eval situations — react

> _Held-out eval content — original, not exam material (no real exam questions; see POLICY.md). Do not paste into a skill body._

Answer each: state the **competent action** and the **reason**. Be concise (2–4 sentences each).

1. A developer defines a `SearchResults` component inside the render body of a `SearchPage` component, because `SearchResults` needs a callback that's defined inside `SearchPage`. The code renders correctly in development. A reviewer flags it as a bug. What is wrong, and what is the correct fix?

2. You have a `UserProfile` component that receives a `userId` prop. Inside the component there is `const [user, setUser] = useState(null)` and a `useEffect` that calls `fetchUser(userId)` and sets the result into state — without a cleanup function. A user rapidly switches between profiles and sees stale data appear momentarily before correcting. What is the root cause, and what is the minimal fix?

3. A component tracks the "currently selected tab" with `useState(tab)` where `tab` is a prop. When the parent updates `tab`, the component stays on the old selection. A teammate adds a `useEffect` that calls `setSelectedTab(tab)` whenever `tab` changes. A senior engineer rejects this. What is the preferred fix — and why is the effect approach a bug?

4. You wrap an expensive list component with `React.memo` and also wrap the sort comparator function passed to it with `useCallback`. After shipping, profiling shows the child still re-renders on every keystroke in an adjacent search input. What is the most likely explanation, and what should you check first?

5. A component subscribes to a browser `resize` event inside a `useEffect` with an empty dependency array `[]`. The handler references a `config` object that is reconstructed on every parent render. After a resize, the handler uses a stale `config`. What rule was violated, and how do you fix it without making `config` a dependency that causes constant re-subscriptions?

6. A team is implementing a large filterable product catalog. The search box is a **controlled input**: `<input value={filter} onChange={e => setFilter(e.target.value)} />`. As users type, React renders the filtered list synchronously and the input visibly lags. A developer proposes fixing this by wrapping the `setFilter` call in `startTransition`. A second developer says to use `useDeferredValue` on `filter` and pass the deferred value to a `memo`-wrapped list component. Which approach is correct, and why does the first approach fail for a controlled input?

7. A `Modal` component uses `useRef` to hold the trigger button element (passed from the parent via prop), so it can restore focus when the modal closes. The ref is read inside a `useEffect` cleanup that runs when the modal unmounts. In some cases the trigger element is gone by the time the cleanup fires, causing a null-dereference. How should focus restoration be structured to be robust?

8. A developer writes a form with an `<input>` whose placeholder text is "Enter your email" and no visible `<label>`. Screen reader users report they cannot identify the field. The developer argues that screen readers read placeholder text. What is the accessibility problem, and what is the correct fix in JSX?

9. A component renders a reorderable drag-and-drop list of tasks. Each task is rendered with `key={index}` (its array index). After a user drags a task from position 0 to position 2, some tasks display incorrect checkbox-checked states. What is the cause, and what is the correct key strategy?

10. A custom hook `useWindowSize` is used by three separate components. A developer on the team expects that all three components share the same window-size state object so that only one `resize` event listener is registered. Is this correct? Describe what actually happens and how you would achieve the shared-listener behavior if needed.

11. In a React Testing Library test, a developer clicks a "Delete" button and immediately asserts with `expect(screen.queryByText('Item A')).not.toBeInTheDocument()`. The deletion triggers a state update and a re-render. The test passes locally but flakes in CI. What is likely wrong, and what is the correct assertion pattern?

12. You are reviewing a component that fetches server data with `useEffect` + `fetch` + `useState`. The reviewer's concern is not about race conditions — the component only ever fetches once on mount. What other concrete problems does this pattern introduce compared to using TanStack Query or SWR, and should you approve the PR?

13. A developer writes a `useAnalytics` custom hook. Inside a `useEffect`, an event is sent to an analytics service whenever a `productId` prop changes. The effect also reads `userId` and `sessionId` from context to include in the payload. Adding `userId` and `sessionId` to the deps array causes the effect to re-fire (and duplicate events) whenever the user's session refreshes, even though `productId` has not changed. The developer removes `userId` and `sessionId` from the deps array to suppress the re-fires, which silences the lint warning but introduces a stale-read bug. What is the React 19.2 idiomatic solution, and what was the pre-19.2 workaround?

14. A developer applies `useDeferredValue` to fix a laggy comment feed that re-renders when the user types in a reply box. They write: `const deferredComments = useDeferredValue(comments)` and pass `deferredComments` to `<CommentList comments={deferredComments} />`. After profiling, the list still re-renders synchronously on every keystroke. What is missing, and what is the exact fix?

15. A `Sidebar` component is toggled open/closed by a boolean prop `isOpen`. When closed, the team wants to hide the sidebar without unmounting it, so that the sidebar's scroll position and sub-component state are preserved for when it reopens. The current implementation conditionally renders `{isOpen && <Sidebar />}`, which unmounts and resets state on close. What React 19.2 primitive should replace this pattern, and what is the key behavioral difference from CSS `display:none` on the outer wrapper?

16. A developer migrates a class component's render prop pattern to a function component. The original code used `React.forwardRef` to expose a DOM node to a parent. A reviewer notes that `forwardRef` is no longer required in React 19. What is the new idiomatic pattern, and what must the function component do differently to accept the `ref`?

17. A component calls `use(UserContext)` conditionally — inside an `if` block — because it only needs the user for a specific feature flag. A teammate says this will violate the Rules of Hooks and suggests moving the call to the top level. Is the teammate correct? Explain the actual rule for `use()` and how it differs from the rules that apply to `useState` or `useEffect`.

18. A developer is asked to implement a tabbed interface where switching tabs should be instant — no loading spinner, no unmount/remount flash — and each tab's scroll position and form state must be preserved. They propose managing this with a `selectedTab` state and rendering all three tab panels simultaneously with CSS `visibility: hidden` on inactive ones. A senior engineer suggests using the React 19.2 `<Activity>` component instead. What concrete advantages does `<Activity>` provide over the CSS-visibility approach, and are there any trade-offs?
