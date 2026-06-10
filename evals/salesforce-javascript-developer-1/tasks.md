# Application tasks — salesforce-javascript-developer-1 (Lens 4, held-out)

A skilled agent produces the artifact; a judge grades against the trap-keyed rubric. Run baseline vs skilled.

---

## Task 1 — LWC code review: record editor with fetch, event, and iteration bugs

**Prompt to the agent:** Review the LWC component below. Redline every reactivity, this-binding, error-handling, and XSS issue you find. For each issue, name the bug, show the broken line(s), explain why it is wrong in LWC specifically, and provide the corrected code.

```js
// recordEditor.js
import { LightningElement, track, wire } from 'lwc';
import getOpenCases from '@salesforce/apex/CaseCtrl.getOpenCases';
import saveCase from '@salesforce/apex/CaseCtrl.saveCase';

export default class RecordEditor extends LightningElement {
    @track cases = [];
    @track errorMsg;

    connectedCallback() {
        getOpenCases()
            .then(result => {
                this.cases = result;
            })
            .catch(err => {
                this.errorMsg = err;
            });
    }

    handleStatusChange(event) {
        const idx = event.target.dataset.index;
        this.cases[idx].Status__c = event.target.value;   // mutate in place
    }

    handleSave() {
        const promises = this.cases.map(c => saveCase({ record: c }));
        Promise.all(promises)
            .then(() => {
                this.dispatchEvent(new CustomEvent('casessaved'));
            });
    }

    get caseRows() {
        return this.cases.map((c, i) => ({ ...c, idx: i }));
    }
}
```

```html
<!-- recordEditor.html -->
<template>
    <template if:true={errorMsg}>
        <p class="error" lwc:dom="manual"></p>
    </template>
    <template for:each={caseRows} for:item="row">
        <div key={row.Id}>
            <input data-index={row.idx} value={row.Status__c}
                   onchange={handleStatusChange} />
            <span lwc:dom="manual" data-desc={row.Description__c}></span>
        </div>
    </template>
    <button onclick={handleSave}>Save All</button>
</template>
```

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — Array element mutation (`this.cases[idx].Status__c = …`) does not trigger `@track` reactivity in LWC because only the array reference (not a nested property mutation) is observed. Fix: replace the element — `this.cases = this.cases.map((c, i) => i === +idx ? { ...c, Status__c: event.target.value } : c)` — or re-assign the array after mutation.
- [ ] Trap 2 — `handleSave` calls `Promise.all` with no `.catch`; an Apex error silently drops the save and leaves the user with no feedback. Fix: add `.catch(err => { this.errorMsg = err.body?.message ?? err; })`.
- [ ] Trap 3 — `lwc:dom="manual"` on `<p class="error">` and `<span data-desc=…>` is being used to display dynamic content. If `this.errorMsg` or `Description__c` is later set via `element.innerHTML = …` in JavaScript (the natural follow-on for `lwc:dom="manual"`), it opens an XSS vector. The correct pattern for text output is data binding (`{errorMsg}`) in the template, not manual DOM manipulation.
- [ ] Trap 4 — `handleSave` is referenced as `{handleSave}` in `onclick` — this is safe in LWC template binding. However if the same method were passed imperatively (e.g., `button.addEventListener('click', this.handleSave)`) it would lose `this`. The review must note this is safe as template-bound but would break if ever extracted to an imperative listener.
- [ ] Trap 5 — `connectedCallback` makes an Apex call but never handles the case where the component is disconnected before the promise resolves, potentially causing a `Cannot set property on destroyed component` error at `this.cases = result`. Fix: guard with a `_connected` flag or use `@wire` for reactive data fetching instead of imperative calls in `connectedCallback`.
- [ ] No new errors introduced

**Reference — a competent redline:**
- Flags the in-place array mutation as the reactivity root cause and provides the immutable-replacement fix.
- Calls out the missing `.catch` on `Promise.all` and provides error surfacing code.
- Identifies `lwc:dom="manual"` + follow-on `innerHTML` as the XSS attack surface and substitutes template data binding.
- Notes the `connectedCallback` + async + component-teardown race and recommends `@wire` or a disconnected guard.
- Correctly characterizes the template-bound `onclick` as safe (no `this`-binding problem in that form).

---

## Task 2 — Jest/LWC-Jest test audit: async flushes, independent awaits, and error coverage

**Prompt to the agent:** Audit the Jest test suite below for an LWC component that wires an Apex adapter and allows filtering. Identify every flaw in async handling, independent-call sequencing, and error coverage. For each flaw produce the corrected test code and explain the impact on test reliability.

```js
// __tests__/caseList.test.js
import { createElement } from 'lwc';
import CaseList from 'c/caseList';
import getCases from '@salesforce/apex/CaseCtrl.getCases';
import getStatuses from '@salesforce/apex/CaseCtrl.getStatuses';

jest.mock('@salesforce/apex/CaseCtrl.getCases', () => ({
    default: jest.fn()
}), { virtual: true });
jest.mock('@salesforce/apex/CaseCtrl.getStatuses', () => ({
    default: jest.fn()
}), { virtual: true });

describe('CaseList', () => {

    afterEach(() => { document.body.innerHTML = ''; });

    it('renders case rows after wire resolves', async () => {
        getCases.mockResolvedValue([
            { Id: '500A', Subject: 'Leak', Status__c: 'Open' }
        ]);

        const el = createElement('c-case-list', { is: CaseList });
        document.body.appendChild(el);

        await Promise.resolve();   // flush micro-tasks

        const rows = el.shadowRoot.querySelectorAll('c-case-row');
        expect(rows).toHaveLength(1);
    });

    it('loads statuses and cases independently and shows filter', async () => {
        getCases.mockResolvedValue([{ Id: '500A', Subject: 'Leak', Status__c: 'Open' }]);
        getStatuses.mockResolvedValue(['Open', 'Closed']);

        const el = createElement('c-case-list', { is: CaseList });
        document.body.appendChild(el);

        await getCases();           // wait for cases specifically
        await getStatuses();        // then statuses

        const filter = el.shadowRoot.querySelector('select');
        expect(filter).not.toBeNull();
        expect(filter.options).toHaveLength(2);
    });

    it('shows error banner on getCases failure', () => {
        getCases.mockRejectedValue({ body: { message: 'Apex error' } });

        const el = createElement('c-case-list', { is: CaseList });
        document.body.appendChild(el);

        const banner = el.shadowRoot.querySelector('.error-banner');
        expect(banner).not.toBeNull();
    });
});
```

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — `await Promise.resolve()` flushes only one microtask tick. A `@wire` adapter resolution typically requires two ticks (one for the mock emit and one for the LWC re-render). The correct flush is `await flushPromises()` imported from `@salesforce/sfdx-lwc-jest` (or a local utility). Failing to do this causes the test to query the DOM before the wire result has been applied, producing a false-positive pass when rows are zero.
- [ ] Trap 2 — In the second test, `await getCases()` and `await getStatuses()` are called sequentially even though the two adapters are independent. This serializes them and slows the test; more critically it does not actually flush the LWC render pipeline — the awaits resolve the mock Promises but do not process the LWC microtask queue. Both awaits should be `await Promise.all([getCases(), getStatuses()])` followed by `await flushPromises()`.
- [ ] Trap 3 — The error-banner test is entirely synchronous — no `await` at all. The `mockRejectedValue` rejection is a Promise that resolves asynchronously; querying the DOM immediately after `appendChild` will always find `null` (no error state has been set yet). The test should be `async` and use `await flushPromises()` before the assertion.
- [ ] Trap 4 — `jest.mock` for `@salesforce/apex` modules uses `{ default: jest.fn() }`. LWC-Jest adapter mocks for `@wire` must use the `@salesforce/sfdx-lwc-jest` mock wiring utilities (`register`, `emit`) when the component uses `@wire`. Plain `mockResolvedValue` only works for imperative Apex calls; using it against a `@wire`-wired method means the wire never emits and the test silently queries an empty DOM. The audit must flag this protocol mismatch.
- [ ] Trap 5 — `afterEach` cleans up via `document.body.innerHTML = ''` which does not call LWC lifecycle hooks (`disconnectedCallback`). The correct teardown is iterating `document.body.children` and calling `document.body.removeChild(el)` for each, or relying on the `@salesforce/sfdx-lwc-jest` test harness reset utility, to ensure proper lifecycle firing.
- [ ] No new errors introduced

**Reference — a competent audit:**
- Replaces all `await Promise.resolve()` with `await flushPromises()` and explains the two-tick LWC render cycle.
- Parallelises independent mock awaits with `Promise.all` and follows with `flushPromises`.
- Converts the synchronous error test to `async` with `flushPromises` before the assertion.
- Flags the `mockResolvedValue` vs `@wire` emit mismatch and shows the correct `registerApexTestWireAdapter` + `emit` pattern.
- Replaces `document.body.innerHTML = ''` teardown with proper element removal to trigger `disconnectedCallback`.
