# Abacus Interface — REST Overhaul via MuleSoft (NG path)

## Goal

Move the Salesforce ↔ Abacus integration from XML-file-drop on a network share to a REST integration brokered by MuleSoft. The new path is built on a **new custom object `AbacusTransferNG__c`** and runs in parallel to the legacy `AbacusInterface__c` machinery — legacy automation is not modified.

## Constraints

- **The old system is not modified.** `AbacusInterface__c`, its fields, flows, file-drop folders, sharing rules, custom metadata, and the middleware that reads the UNC share are left untouched.
- **The new path is isolated.** All new schema lives on `AbacusTransferNG__c` and supporting metadata. The new path never writes to `AbacusInterface__c` and vice versa.
- **Accountant approval is explicit and per-row.** Nothing is sent to Abacus without the accounting team (FinanceQueue) reviewing the queued row and clicking **Approve & Push** on it. The accountant's gesture on the source record (e.g. `AbacusDebtor__c`) *queues* the work; the approval click on the AbacusTransferNG__c row *releases* it to Mule.
- **Finance/audit visibility lives in Salesforce.** `AbacusTransferNG__c` is the source of truth for "what was queued, who approved it, what was sent, what came back" for the REST path. Approval is stamped on the row (`ApprovedBy__c`, `ApprovedAt__c`).
- **Idempotent.** Replay must never double-post to Abacus.

## Accounting Verification Gate

For outbound interfaces, there is a **single approval gate** owned by the accounting team:

1. **Queueing is automatic** — when the source record changes in a way the legacy file-drop path would have triggered (e.g. `AbacusDebtor__c` flipped on, `AbacusInterfaceExport__c` ticked on an invoice), a record-triggered flow inserts an `AbacusTransferNG__c` row with `Status__c = 'Pending Approval'`. No action is required on the source record beyond what was already being done there.
2. **Approval happens in batches from the list view.** The accounting team (FinanceQueue) opens the `AbacusTransferNG__c` list view (typically the "Pending Approval" view), multi-selects the rows they deem ready to send, and clicks the **Approve & Push Selected** list view button. The screen flow filters to rows currently in `Pending Approval`, then stamps `ApprovedBy__c` / `ApprovedAt__c`, flips `Status__c` to `Pending`, and publishes one `AbacusTransferNGQueued__e` Platform Event per row. Mule takes it from there.

Approval is bulk-by-design: there is no per-record approval button. The list view is the gate.

| Interface Type | Source record | Queue trigger | Approval required? |
|---|---|---|---|
| Invoice Export | `Invoice__c` | `AbacusInterfaceExport__c` ticked | Yes (FinanceQueue, bulk from list view) |
| Cancellation Export | `Invoice__c` (canceled) | `AbacusInterfaceExport__c` on the cancellation | Yes (FinanceQueue, bulk from list view) |
| Account Debtor Upsert | `Account` | `AbacusDebtor__c` flips on, or tracked address fields change | Yes (FinanceQueue, bulk from list view) |
| Account Supplier Upsert | `Account` | `AbacusSupplier__c` flips on, or tracked key fields change | Yes (FinanceQueue, bulk from list view) |
| Staff Hour Export | `Time__c` / scheduled batch | Existing aggregation rules (unchanged) | Yes (FinanceQueue, bulk from list view) |
| Project Export | `Project__c` | Project create or change of any tracked Abacus field | **No — auto-published** (NG-only, no legacy equivalent) |
| Currency Import | n/a (inbound) | — | n/a (inbound) |

**Why list-view bulk and not per-record.** Approval is a finance-team workflow, not a per-record decision moment. The accounting team works through a queue: they review what's accumulated since the last sweep, multi-select what looks good, release it in a batch. Forcing them to open each record individually would turn approval into busy-work; the list view is the natural workspace.

**Where the verification status is visible**:

- On the source record, the existing formula field `Invoice__c.AbacusStatus__c` continues to reflect the lifecycle in finance-readable terms (`READY` → `SELECTED TO TRANSFER` → `TRANSFERRED`) and is **not modified** by this plan. Mule stamps `Invoice__c.AbacusTransfer__c` on success — same field, same timing as the legacy path — so the existing formula keeps working.
- On the queued row, `Status__c` + `ApprovedBy__c` + `ApprovedAt__c` give the finance team a full audit trail of who approved what and when.

**Reverting before approval**: if the accountant unticks the source-record verification before a FinanceQueue member has approved the row, a companion flow on `AbacusTransferNG__c` moves the still-`Pending Approval` row to `Cancelled` so it never appears in the approval batch.

## Target Architecture

```
                    ┌─────────────────────────────────────────────────────┐
                    │                 Salesforce (BLC)                    │
                    │                                                     │
   record change ─► │ Source record (Account / Invoice / Project / …)    │
                    │        │                                            │
                    │        ▼ (record-triggered flow, matches legacy     │
                    │           trigger conditions)                       │
                    │                                                     │
                    │     AbacusTransferNG__c row (Status=PendingApproval)│
                    │                          │                          │
                    │                          ▼                          │
                    │   FinanceQueue opens the AbacusTransferNG list view │
                    │   multi-selects rows, clicks "Approve & Push        │
                    │   Selected" (list-view button → screen flow         │
                    │   → AbacusTransferNGReplayAction Apex)              │
                    │                          │                          │
                    │   ApprovedBy/ApprovedAt stamped, Status=Pending     │
                    │                          │                          │
                    │                          └─► PE AbacusTransferNG..  │
                    └─────────────────────┬───────────────────────────────┘
                                          │
                                ┌─────────▼──────────┐
                                │     MuleSoft       │
                                │  - subscribe PE    │
                                │  - fetch NG + src  │
                                │  - DataWeave map   │
                                │  - call Abacus REST│
                                │  - retry / DLQ     │
                                │  - callback to SF  │
                                └─────────┬──────────┘
                                          │
                                ┌─────────▼──────────┐
                                │   Abacus REST API  │
                                └────────────────────┘
```

**Direction of work**:
- Salesforce *queues* the transfer when the source record changes.
- An accountant *approves* the row, which publishes a Platform Event.
- Mule *does* the work: read source, transform, call Abacus, retry, DLQ.
- Mule *writes back* via Salesforce REST to update the `AbacusTransferNG__c` row with status, Mule correlation id, Abacus document id, last HTTP status, last error.
- Mule also stamps the source record's existing Abacus tracking fields (e.g. `Invoice__c.AbacusTransfer__c`) on success — so the existing post-transfer flows (like `InvoiceStatusSentToAbacusWhenTransferDateNotNull`) keep firing unchanged.

`AbacusTransferNG__c` is an **outbox + audit log**, not a working queue. Mule's persistent queue (Anypoint MQ or VM persistent) is the actual queue.

## New Object: `AbacusTransferNG__c`

Auto-number `Name`: `ABNG-{0000000}`.

| API name | Type | Purpose |
|---|---|---|
| `InterfaceType__c` | Picklist | Seven values — six mirror `AbacusInterface__c.InterfaceType__c` (Account Debtor Upsert / Account Supplier Upsert / Invoice Export / Cancellation Export / Staff Hour Export / Currency Import) plus **Project Export** (NG-only, no legacy equivalent). |
| `Direction__c` | Picklist (`Outbound`, `Inbound`) | `Outbound` for SF→Abacus, `Inbound` for Abacus→SF. |
| `Status__c` | Picklist | `Pending Approval`, `Pending`, `Dormant`, `InFlight`, `Sent`, `Failed`, `DeadLettered`, `Cancelled`. Default `Pending Approval` for new outbound rows. |
| `SourceObject__c` | Text(80) | API name of the source SObject, e.g. `Invoice__c`. |
| `SourceRecordId__c` | Text(18), Indexed | Id of the source record. |
| `Account__c` | Lookup(Account) | Populated for debtor/supplier upserts. |
| `Invoice__c` | Lookup(Invoice__c) | Populated for Invoice Export / Cancellation Export. |
| `SupplierInvoice__c` | Lookup(SupplierInvoice__c) | Populated for inbound supplier invoices. |
| `SupplierCosts__c` | Lookup(SupplierCosts__c) | Populated for supplier-cost imports. |
| `Project__c` | Lookup(Project__c) | Populated for Project Export and for Staff Hour Export when project-scoped. |
| `IdempotencyKey__c` | Text(40), External Id | Defaults to `Name`. Passed to Abacus via `Idempotency-Key` header. Uniqueness is guaranteed by the auto-number `Name` it's seeded from. |
| `MuleCorrelationId__c` | Text(64) | Mule transaction id, written on callback. |
| `AbacusDocumentId__c` | Text(64) | External id assigned by Abacus on success. |
| `LastHttpStatus__c` | Number(3,0) | HTTP code from the last Mule → Abacus attempt. |
| `LastError__c` | Long Text Area | Error message body from Mule. |
| `LastAttemptAt__c` | DateTime | When Mule last tried. |
| `RetryCount__c` | Number(3,0) | Incremented by Mule on each retry. |
| `SentAt__c` | DateTime | Stamped when `Status__c` → `Sent`. |
| `PayloadSnapshot__c` | Long Text Area | Optional; capture the transformed payload at queue time for audit. |
| `ApprovedBy__c` | Lookup(User) | Set when a FinanceQueue member clicks Approve & Push. Cleared otherwise. |
| `ApprovedAt__c` | DateTime | Set at the same moment as `ApprovedBy__c`. |

### Platform Event

`AbacusTransferNGQueued__e` — published by the `AbacusTransferNGReplayAction` Apex class on approval (and on manual replay). Carries:

- `AbacusTransferNGId__c` (Text 18)
- `InterfaceType__c` (Text 80)
- `IdempotencyKey__c` (Text 40)

Mule's Salesforce connector subscribes to this PE.

## Salesforce-Side Changes

### Source-record-triggered flows (queue gesture)

One record-triggered flow per source object creates `AbacusTransferNG__c` rows in `Status__c = 'Pending Approval'` when the same trigger conditions that drive the legacy file-drop flow are met:

- `RTF_Account_AbacusTransferNG_Debtor` — Account becomes a debtor or tracked billing fields change while debtor=true.
- `RTF_Account_AbacusTransferNG_Supplier` — Account becomes a supplier or tracked key fields change while supplier=true.
- `RTF_Account_AbacusTransferNG_Cancel` — debtor or supplier flag is unticked → any still-Pending-Approval rows for the Account flip to `Cancelled`.
- `RTF_Invoice_AbacusTransferNG` — `AbacusInterfaceExport__c` flips on.
- `RTF_Invoice_AbacusTransferNG_Cancel` — companion cancellation flow.
- `RTF_Invoice_AbacusTransferNG_Cancellation` — cancellation invoice path.
- `RTF_Invoice_AbacusNGTransfer_Finalise` — after Mule callback flips `AbacusNGTransfer__c`, finalises invoice status (`InvoiceStatus__c = 'Sent'`).
- `RTF_Project_AbacusTransferNG` — project create or change of any tracked Abacus field. **Bypasses approval** (auto-publishes), since Project Export has no accountant gate.

The trigger conditions of each flow mirror the existing legacy flow that creates `AbacusInterface__c` rows, so the *moment of queueing* is identical from the user's perspective.

### Approval flow (release gesture)

- `RTF_AbacusTransferNG_BulkApproveAndPush` is a screen flow exposed as the **Approve & Push Selected** list view button (a `WebLink` with `displayType=massActionButton`) on `AbacusTransferNG__c`. The button URL passes the selected record Ids to the flow as a Text collection.
- The flow:
  1. Queries the `AbacusTransferNG__c` rows whose Ids were selected AND whose `Status__c = 'PendingApproval'`. Rows in any other status are silently filtered out — the accountant can multi-select freely without worrying about already-released or cancelled rows.
  2. Shows a confirmation screen identifying how many rows are about to be released.
  3. Loops the eligible rows into a String collection of Ids.
  4. Calls `AbacusTransferNGReplayAction.replay({abacusTransferNGIds: [...]})` once with the full collection. The Apex method updates each row in one DML (`Status__c = 'Pending'`, `ApprovedBy__c = $User.Id`, `ApprovedAt__c = now`) and publishes one `AbacusTransferNGQueued__e` Platform Event per row in one `EventBus.publish` call.
  5. Shows a success screen.

The same `AbacusTransferNGReplayAction` Apex method is reused for the **Replay** workflow on `Failed` / `DeadLettered` rows. Its `Request` class accepts either a single `abacusTransferNGId` or a collection `abacusTransferNGIds` — the bulk approval flow uses the collection form, the manual replay invocation uses either.

### Inbound (Currency Import, Supplier Invoice)

Apex REST resource `AbacusTransferNGInboundRest` at `/services/apexrest/abacus/v1/inbound/*`. The endpoint:

1. Validates the `Idempotency-Key` header — if an `AbacusTransferNG__c` row already exists with that key, returns the original response.
2. Creates an `AbacusTransferNG__c` row with `Direction__c = 'Inbound'`, `Status__c = 'Sent'`, `SentAt__c = now`.
3. Upserts the target record (Currency / SupplierInvoice / SupplierCosts) in the same transaction.
4. Returns `{ abacusTransferNGId, status }`.

The legacy inbound file-drop reader is untouched and keeps running for any inbound interface type still on the legacy path.

### Permission sets

- `PS_Abacus_Mule_Integration` — for the Mule integration user. CRUD on `AbacusTransferNG__c`, read on source objects, edit on the few stamp fields (e.g. `Invoice__c.AbacusNGTransfer__c`), Apex class access. No access to legacy `AbacusInterface__c`.
- `PS_AbacusTransferNG_Approver` — for FinanceQueue members. Read on all `AbacusTransferNG__c` rows, edit on `Status__c` + `ApprovedBy__c` + `ApprovedAt__c`, visibility of the `Approve_and_Push` quick action, Apex access to `AbacusTransferNGReplayAction`.

### What is NOT changed on Salesforce

- `AbacusInterface__c` — schema, fields, statuses, picklist values, layouts, sharing rules, tab, topics-for-objects: unchanged.
- The file-drop folders on `\\BLC-ABA-01\SkywalkAbacusIntegration\...` and the middleware reading them: unchanged.
- Custom metadata `Field.Account_AbacusDebtor`, `Field.Account_AbacusSupplier`, `ParentObjectUpdate.Invoice2Account_AbacusDebtor`: unchanged.
- Duplicate rule on `SupplierCosts__c`: unchanged.
- Invoice formula field `AbacusStatus__c` (READY / SELECTED TO TRANSFER / TRANSFERRED): unchanged — Mule stamps `Invoice__c.AbacusTransfer__c` on success, exactly like the file-drop path did.
- `InvoiceStatusSentToAbacusWhenTransferDateNotNull` flow: unchanged.
- Existing legacy flows (`AbacusInterfaceAccountUpsert`, `AbacusInterfaceAccountUpsertSupplier`, `PackageSupplierCostsAbacusInbox`): unchanged. Both paths can in principle fire on the same source change; in practice the user-facing queue is `AbacusTransferNG__c` and the legacy `AbacusInterface__c` rows are observed-but-ignored. Future work could add an explicit gate (e.g. CMDT mode flag) if dual-firing becomes operationally relevant.

## MuleSoft-Side Responsibilities

1. **Subscribe** to `AbacusTransferNGQueued__e` via the Salesforce connector. Each event → one job.
2. **Fetch** the `AbacusTransferNG__c` row and the related source record (resolved via `SourceObject__c` + `SourceRecordId__c`) in one or two SOQL calls. If the row's `Status__c` is `Cancelled` by the time Mule reads it, drop the message (the accountant unticked the verification flag before approval, or the row was manually cancelled).
3. **Set `Status__c = 'InFlight'`** and `LastAttemptAt__c = now` (single PATCH).
4. **Transform** with DataWeave into the Abacus REST payload. One DataWeave module per `InterfaceType__c`. Optionally write the transformed payload back to `PayloadSnapshot__c`.
5. **Call Abacus** with header `Idempotency-Key: {IdempotencyKey__c}`. Use `until-successful` for retry; on terminal failure, push to DLQ (Anypoint MQ).
6. **Callback to Salesforce** PATCH `AbacusTransferNG__c`:
   - On 2xx: `Status__c = 'Sent'`, `AbacusDocumentId__c`, `LastHttpStatus__c`, `MuleCorrelationId__c`, `SentAt__c`. For Invoice Export, **additionally** PATCH `Invoice__c.AbacusTransfer__c = now` so the existing post-transfer flow finalises the invoice — no change to that flow.
   - On terminal failure: `Status__c = 'Failed'`, `LastHttpStatus__c`, `LastError__c`, `RetryCount__c`.
   - On DLQ: `Status__c = 'DeadLettered'`.
7. **Named Credentials** for the Salesforce callback (Mule → SF) live in Mule's secure properties. The Salesforce → Abacus credentials never leave Mule.

The existing mapping CMDT records (`Field.Account_AbacusDebtor` etc.) are **not** consumed by Mule; DataWeave owns the NG-path mapping.

## Status Lifecycle

```
   Legacy path (AbacusInterface__c) — unchanged
   ┌─────────────────────────────────────────────────────┐
   │  Prepared → Queued → Finished (No Errors|With Err.) │
   └─────────────────────────────────────────────────────┘

   NG path (AbacusTransferNG__c)
   ┌─────────────────────────────────────────────────────┐
   │  Pending Approval ──► Pending ──► InFlight ──► Sent │
   │       │                  │            │             │
   │       │                  │            └► Failed ──► DeadLettered │
   │       │                  │                          │
   │       └──► Cancelled     └──► Cancelled (rare)      │
   │       (accountant un-                               │
   │        ticked before                                │
   │        approval)                                    │
   │                                                     │
   │  Project Export bypasses Pending Approval:          │
   │  flow creates rows in Pending directly.             │
   └─────────────────────────────────────────────────────┘
```

Reports filter on the relevant object. No collisions because the two paths use different objects.

## Idempotency

- `IdempotencyKey__c` is an External Id, defaulting to the auto-number `Name`. Because `Name` is unique by construction, the key is unique in practice.
- Mule sends `Idempotency-Key` header on every Abacus call. Abacus must treat duplicate keys as no-ops returning the original response — hard requirement on the Abacus REST contract.
- On Salesforce callback, Mule PATCHes by `IdempotencyKey__c` (External Id upsert), so even if a callback retries, the row converges.
- Inbound: the Apex REST endpoint also keys on `Idempotency-Key`, so Mule retrying an inbound delivery doesn't double-insert.

## Error Handling & Retries

- **Retries live in Mule**, not Salesforce. Apex never reschedules.
- Mule retry policy: exponential backoff, e.g. 1m / 5m / 30m / 2h / 12h, then DLQ.
- DLQ alerts go to the integrations channel (Slack / email — TBD with ops).
- Salesforce list views on `AbacusTransferNG__c` (`Pending Approval`, `Open`, `Failed`, `DeadLettered`, etc.) give finance and ops a view of where every row is.
- Manual replay = reuse the same `AbacusTransferNGReplayAction` invocable from a list view button or the Approve & Push quick action. It resets `Status__c = 'Pending'`, clears `LastError__c` / `LastHttpStatus__c`, and publishes a fresh `AbacusTransferNGQueued__e`.

## Open Questions / Decisions

- **Abacus REST contract**: who owns the OpenAPI spec? Need confirmation that Abacus honours `Idempotency-Key` semantics. If not, idempotency must be enforced inside Mule (lookup-before-write) — slower and not bulletproof.
- **Auth Mule ↔ Abacus**: OAuth 2.0 client credentials assumed. Confirm with Abacus admin.
- **Auth Mule ↔ Salesforce**: connected app `Abacus_MuleSoft_Integration` + JWT bearer for Mule, scoped to a service user with `PS_Abacus_Mule_Integration` permset.
- **Volume**: current peak rows/day on `AbacusInterface__c` → sizes the Mule worker tier and decides Anypoint MQ vs VM queue.
- **Replay window**: confirm Mule DLQ retention matches finance's reconciliation window (typically 90 days for month-end close).
- **PE vs CDC**: starting with Platform Events; CDC is a fallback if Mule's PE subscription proves lossy under load.
- **Per-record fast path**: the only approval entry point today is the list view. If finance asks for a one-click approval from inside an open record (e.g. while investigating a single Pending Approval row), the `RTF_AbacusTransferNG_BulkApproveAndPush` flow could be reused as a per-record quick action that pre-fills `ids` with the single record's Id.

## What Stays Untouched

For clarity, the following are **not modified or removed** by this plan:

- `AbacusInterface__c` object — schema, fields, layouts, sharing rules, tab, topicsForObjects: untouched.
- `Status__c` picklist on `AbacusInterface__c`: no new values, no relabels.
- The UNC share `\\BLC-ABA-01\SkywalkAbacusIntegration\...` and whatever middleware reads it: untouched.
- Custom metadata `Field.Account_AbacusDebtor`, `Field.Account_AbacusSupplier`, `ParentObjectUpdate.Invoice2Account_AbacusDebtor`: untouched.
- Existing legacy flows (`AbacusInterfaceAccountUpsert`, `AbacusInterfaceAccountUpsertSupplier`, `InvoiceStatusSentToAbacusWhenTransferDateNotNull`, `PackageSupplierCostsAbacusInbox`): unchanged.
- Duplicate rule on `SupplierCosts__c.Supplier_Cost_Abacus_Doc_Nr_Pos_Nr`: untouched.
- Invoice formula field `AbacusStatus__c` (READY / SELECTED TO TRANSFER / TRANSFERRED): untouched.
- All `Abacus*` fields on Account, Invoice, SupplierInvoice, SupplierCosts, Project, Contact, Time: untouched.
