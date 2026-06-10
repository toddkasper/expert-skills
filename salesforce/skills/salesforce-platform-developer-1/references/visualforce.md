# PD1 — Visualforce Reference

Deep-dive companion to [../SKILL.md](../SKILL.md). Load when working on Visualforce pages, PDF rendering, or Classic-era UI customizations.

---

## When to Use Visualforce

| Use case | Tool |
|---|---|
| PDF generation | Visualforce with `renderAs="pdf"` on the `<apex:page>` tag — the only reliable PDF path in Salesforce |
| Classic org UI customization | Visualforce (Classic pages, sidebar components) |
| Legacy embed in Lightning (iframe) | Visualforce page hosted in a Lightning component — use sparingly |
| New Lightning UI | LWC (do not write new Visualforce for Lightning) |

---

## Controller Types

| Type | How to declare | When to use |
|---|---|---|
| **Standard controller** | `standardController="Account"` on `<apex:page>` | Quick UI on a single standard/custom object — gets save/cancel/edit for free |
| **Standard controller + extension** | `extensions="MyExtension"` alongside `standardController=` | Add extra methods/properties to a standard controller without replacing it |
| **Custom controller** | `controller="MyController"` (no `standardController`) | Full control; standard save/cancel/edit must be reimplemented manually |

Extension class constructor signature: `public MyExtension(ApexPages.StandardController stdController)`. Extension methods run in the extension's sharing context, not the page controller's.

---

## View State and Performance

- **View State limit: 170 KB.** Exceeding it throws a page error on postback.
- Mark fields that don't need to survive a postback as `transient` on the controller to exclude them from View State: `public transient String tempValue { get; set; }`.
- Large collections (e.g. thousands of `SelectOption`s) are common view-state offenders — paginate or lazy-load.
- Use `<apex:actionFunction>` and `<apex:actionSupport>` for partial-page AJAX refreshes rather than full postbacks when possible.

---

## XSS Safety

- Default `<apex:outputText>` and `<apex:outputField>` output is **HTML-encoded** — safe by default.
- `escape="false"` bypasses HTML encoding and requires explicit developer justification (e.g., rendering intentional HTML). Never use on user-supplied content.
- For values written into inline JavaScript: use `{!JSENCODE(myVar)}` (not just `{!myVar}`) to prevent script injection.
- For URLs built from user data: `{!URLENCODE(myVar)}`.

---

## Testing Visualforce Pages

```apex
@isTest
static void testMyPage() {
    Account a = new Account(Name='Test');
    insert a;
    Test.setCurrentPage(Page.MyPage);
    ApexPages.StandardController sc = new ApexPages.StandardController(a);
    MyExtension ext = new MyExtension(sc);
    System.assertEquals('expected', ext.someProperty);
}
```

- `Test.setCurrentPage(Page.MyPageName)` sets the page context for controller tests.
- For URL parameters: `ApexPages.currentPage().getParameters().put('id', a.Id)`.
- Coverage applies the same 75% rule as all Apex.

---
*Companion reference — independent educational content, not affiliated with or endorsed by any vendor; product/credential names are used for identification only. Guidance, not ground truth — verify against official docs. Full disclaimer: the parent `SKILL.md` and the repo `POLICY.md`.*
