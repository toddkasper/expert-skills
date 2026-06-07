# Eval situations — salesforce-javascript-developer-1 (held-out set, 2026-06-07)

Answer each: state the **competent action** and the **reason**. Be concise (2–4 sentences each).

1. A component build pipeline snapshot-serializes a Salesforce SOQL response to a JSON file for later processing. The response includes a `CreatedDate` field whose value is a JavaScript `Date` object. A downstream script reads the file and tries to call `.getFullYear()` on the field — it throws `TypeError: createdDate.getFullYear is not a function`. No errors occurred during serialization. What happened, and what is the correct fix?

2. An LWC component tracks a `selectedIds` property (a `Set`) to record which rows a user has checked in a table. The developer adds each selected id with `this.selectedIds.add(id)` and has a getter that returns the size. After checking several rows, the count displayed in the template never changes. What is wrong and how do you fix it?

3. A Node.js Lambda function reads a large CSV export from S3 and loads all its bytes into memory with `fs.readFileSync`, then parses each row. In test with a 2 MB file it works fine; in production with a 450 MB file the Lambda hits its memory limit and crashes. What is the architectural fix?

4. A developer needs to check whether a variable `apiResponse` is either `null` or `undefined` before accessing `.records` on it. They write `if (apiResponse == null)`. A code reviewer flags this as a bug. Is the reviewer correct, and why or why not?

5. An LWC child component dispatches an event named `record-Updated` with `bubbles: true` and `composed: true`. The parent component has a handler bound as `onrecord-Updated` in its template. In the browser, the handler never fires. What are the two config errors, and what is the correct event name and template binding?

6. A developer writes an async Jest test for a function that calls an Apex method mock:

   ```js
   it('loads records on connect', () => {
     const el = createElement('c-my-comp', { is: MyComp });
     document.body.appendChild(el);
     getRecordsMock.mockResolvedValue([{ id: '001' }]);
     expect(el.shadowRoot.querySelectorAll('c-row')).toHaveLength(1);
   });
   ```

   The test passes consistently, yet the feature is broken in the browser. What is wrong with the test?

7. A Node.js Express service caches metadata objects fetched from Salesforce in a `Map` keyed by the LWC component class instance that requested them. The service is long-running. Ops notices memory grows unboundedly over hours even though the requesting component objects are never referenced again by application code. What data structure should replace `Map` here and why?

8. A developer wants to deduplicate a list of Salesforce record IDs returned from two SOQL queries and immediately iterate over the unique set. They write:

   ```js
   const unique = { ...setA, ...setB };
   for (const id of unique) { … }
   ```

   The code throws `TypeError: unique is not iterable` at runtime. What went wrong, and what is the correct pattern?

9. A class method `save()` is passed as a callback to a third-party form library: `form.onSubmit(this.save)`. Inside `save`, `this.recordId` is `undefined`, even though the component instance has that property set. A teammate suggests wrapping it as `form.onSubmit(() => this.save())`. Does the anonymous-arrow wrapper fix the `this` problem, and is there any downside?

10. A team's CI pipeline uses `npm install` rather than `npm ci`. After a minor dependency was bumped upstream (compatible range, no lockfile change), unit tests start failing non-deterministically across different CI agents. What is the root cause, and what should the CI command be?

11. A developer writes a loop that attaches click listeners to a list of buttons, intending each handler to log the button's index:

    ```js
    for (var i = 0; i < buttons.length; i++) {
      buttons[i].addEventListener('click', function() {
        console.log(i);
      });
    }
    ```

    After deploying, every button logs the same number regardless of which one is clicked. What is the bug, and what is the minimal correct fix?

12. A `Promise.all` call fans out three independent imperative Apex fetches. One of the three Apex methods occasionally throws a permission error for guest users. After the error, none of the three results are used and the component shows a full error state even though the other two calls succeeded. What change would let the component display partial results for the two succeeding calls while surfacing only the failed one's error separately?
