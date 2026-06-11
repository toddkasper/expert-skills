# PD2 — Visualforce Reference

Load-on-demand companion to [../SKILL.md](../SKILL.md). Use when building or reviewing Visualforce pages, or working through PD2 User Interface exam topics (~20% of exam blueprint).

Visualforce is a legacy UI framework but remains explicitly tested in PD2. New development should use LWC; write VF only when a platform capability requires it (notably PDF rendering).

---

## StandardSetController (paginated list views)

Use `ApexPages.StandardSetController` for any paginated list in Visualforce — do NOT write custom OFFSET-based pagination (`OFFSET` caps at 2,000 records).

```apex
public ApexPages.StandardSetController setCon { get; set; }

public MyController() {
    setCon = new ApexPages.StandardSetController(
        Database.getQueryLocator([SELECT Id, Name FROM Invoice__c ORDER BY Name])
    );
    setCon.setPageSize(20);
}

public List<Invoice__c> getInvoices() {
    return (List<Invoice__c>) setCon.getRecords();
}
```

Visualforce navigation buttons:
```xml
<apex:commandButton action="{!setCon.previous}" value="Previous"
    disabled="{!NOT(setCon.hasPrevious)}" reRender="listPanel"/>
<apex:commandButton action="{!setCon.next}"     value="Next"
    disabled="{!NOT(setCon.hasNext)}"     reRender="listPanel"/>
```

| Method | Returns |
|---|---|
| `getRecords()` | Current page's records (cast to `List<SObject>`) |
| `setPageSize(n)` | Sets records per page |
| `first()` / `last()` | Jump to first/last page |
| `next()` / `previous()` | Advance/retreat one page |
| `hasNext()` / `hasPrevious()` | Boolean — use to disable nav buttons |
| `getResultSize()` | Total record count across all pages |

---

## Controller Extensions

A controller extension receives an `ApexPages.StandardController` (or `ApexPages.StandardSetController`) as its constructor argument. It adds methods and properties on top of the standard controller without replacing it.

```apex
public class InvoiceExtension {
    private ApexPages.StandardController stdCtrl;
    public InvoiceExtension(ApexPages.StandardController ctrl) {
        this.stdCtrl = ctrl;
    }
    public String getStatus() {
        Invoice__c inv = (Invoice__c) stdCtrl.getRecord();
        return inv.Status__c;
    }
}
```

Declare in the page:
```xml
<apex:page standardController="Invoice__c" extensions="InvoiceExtension">
```

**Multiple extensions:** `extensions="ExtA,ExtB"` — methods resolved left-to-right; first class wins on name collision.

---

## Partial Page Refresh

Refresh a specific region without a full page reload using `reRender` on action components.

```xml
<apex:form>
    <apex:outputPanel id="statusPanel">
        <apex:outputText value="{!status}"/>
    </apex:outputPanel>

    <!-- Refresh on button click -->
    <apex:commandButton value="Refresh" action="{!recalculate}" reRender="statusPanel"/>

    <!-- Refresh on field change (no button) -->
    <apex:inputField value="{!record.Type__c}">
        <apex:actionSupport event="onchange" action="{!onTypeChange}" reRender="statusPanel"/>
    </apex:inputField>

    <!-- Callable from JavaScript -->
    <apex:actionFunction name="jsRefreshStatus" action="{!recalculate}" reRender="statusPanel"/>
</apex:form>
```

Call `jsRefreshStatus()` from JavaScript to trigger server-side refresh from client code.

---

## JavaScript DOM Targeting (`{!$Component}`)

Visualforce prefixes all rendered component `id` attributes with the full component hierarchy path (e.g. `j_id0:myForm:statusPanel`). `document.getElementById('statusPanel')` always fails.

**Correct pattern:**
```xml
<apex:outputPanel id="statusPanel">...</apex:outputPanel>
<script>
    var panelId = '{!$Component.statusPanel}';  // outputs the full rendered id
    document.getElementById(panelId).style.display = 'none';
</script>
```

If the component is nested inside a form named `myForm`:
```xml
var panelId = '{!$Component.myForm.statusPanel}';
```

---

## Error Handling

```apex
// In controller action method
ApexPages.addMessage(
    new ApexPages.Message(ApexPages.Severity.ERROR, 'Something went wrong.')
);

// Return null to stay on the same page
return null;
```

```xml
<!-- In the page: renders all messages -->
<apex:pageMessages/>
<!-- Or per-field: -->
<apex:inputField value="{!record.Amount__c}"/>
<apex:message for="Amount__c"/>
```

Severity levels: `ERROR`, `WARNING`, `INFO`, `CONFIRM`, `FATAL`.

---

## PDF Rendering

```xml
<apex:page renderAs="pdf" controller="InvoicePdfController">
    <apex:outputText value="{!invoice.Name}"/>
</apex:page>
```

- Only PDF output via `renderAs="pdf"` is a common use case for **new** Visualforce pages.
- CSS and JavaScript have limited support in PDF mode; keep layouts simple and use inline styles.
- `contentType="application/pdf#filename.pdf"` on `<apex:page>` controls the filename in the browser download prompt.

---

## Security note

Visualforce pages running with a `without sharing` controller serve field values without FLS enforcement by default. For Visualforce pages that display or capture user data:
- Use `with sharing` on the controller class (enforces record-level sharing but not FLS).
- Add explicit FLS checks (`Schema.sObjectType.X.fields.Y.isAccessible()`) or `Security.stripInaccessible()` before rendering sensitive fields.

---

*Companion reference — independent educational content, not affiliated with or endorsed by any vendor. Full disclaimer: the parent `SKILL.md` and the repo `POLICY.md`.*
