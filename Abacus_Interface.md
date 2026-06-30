# Abacus Interface — REST Overhaul via MuleSoft (Strictly Isolated NG Path)

## Goal

Move the Salesforce ↔ Abacus integration from XML-file-drop on a network share to a REST integration brokered by MuleSoft. The new path is built around a **new custom object `AbacusTransferNG__c`** that runs **strictly in parallel** with the existing `AbacusInterface__c` machinery. Nothing about the existing implementation is modified — every file, flow, field, class, layout, sharing rule, custom-metadata record, and middleware behaviour stays exactly as it is today. The cutover decision (when to actually call Abacus over REST, and when to silence the file-drop) lives outside Salesforce: in Mule's configuration and the legacy middleware's configuration.

## Locked Constraints

1. **Strict isolation.** Zero edits to any existing metadata file. The new path coexists with the legacy file-drop path without modifying a single existing flow, class, layout, object, field, permission set, custom metadata record, or trigger.
2. **Parallel emission.** When the accounting team takes the verification gesture they take today (ticking `Invoice__c.AbacusInterfaceExport__c`, `Account.AbacusDebtor__c`, etc.), the existing flow still creates an `AbacusInterface__c` row exactly as today, and a **new parallel flow** also creates an `AbacusTransferNG__c` row. Both rows exist; both events are emitted.
3. **Mule owns the "send to Abacus" decision.** Per `InterfaceType__c`, Mule is configured `Dormant` or `Live`. While Dormant, Mule consumes the NG Platform Event but does not call Abacus. While Live, Mule transforms and calls Abacus REST.
4. **The legacy middleware owns the "stop the file drop" decision.** When an `InterfaceType__c` is cut over, ops turns off the legacy middleware's processing of that folder. Until then, the legacy path keeps running.
5. **Invoice finalisation lives on a new field.** Mule stamps `Invoice__c.AbacusNGTransfer__c` (new field) on success; a new finalisation flow watches that field and drives `InvoiceStatus__c = 'Sent'`. The existing `Invoice__c.AbacusTransfer__c` field and [InvoiceStatusSentToAbacusWhenTransferDateNotNull.flow-meta.xml](force-app/main/default/flows/InvoiceStatusSentToAbacusWhenTransferDateNotNull.flow-meta.xml) are not touched.
6. **Accounting verification is preserved.** No transfer is initiated without the accounting team's existing verification gesture. Both paths trigger off the same checkbox; the accounting team sees no UX difference.
7. **Idempotent.** Replay must never double-post to Abacus.

## Accounting Verification Gate

For outbound interfaces, no transfer is initiated until the accounting team explicitly flags the source record as ready. This is unchanged from today: the same checkboxes that gate the legacy file-drop path also gate the NG path. The new flows watch for the same flag transitions as the legacy flows do.

| Interface Type | Source record | Verification field | Behaviour |
|---|---|---|---|
| Invoice Export | `Invoice__c` | `AbacusInterfaceExport__c` | Accountant reviews the invoice and ticks the checkbox. The legacy flow (unchanged) and the new NG flow both trigger on this transition. |
| Cancellation Export | `Invoice__c` (cancellation) | `AbacusInterfaceExport__c` | Same field, used on the cancellation invoice. |
| Account Debtor Upsert | `Account` | `AbacusDebtor__c` | Accountant marks the account as a debtor; reverification when key fields change. |
| Account Supplier Upsert | `Account` | `AbacusSupplier__c` | Same pattern for suppliers. |
| Staff Hour Export | `Time__c` / scheduled batch | (existing trigger logic, unchanged) | Aggregated on schedule; the gate lives in the existing aggregation rules. New NG batch mirrors the legacy aggregation. |
| Project Export | `Project__c` | **none — auto-transfer** | Fires on project create and on update of any tracked Abacus field (`AbacusProjectNr__c`, `AbacusProjectName__c`, `AbacusProjectAbbreviation__c`, `AbacusProjectStatus__c`, `AbacusProjectType__c`, `AbacusResponsible__c`, etc.). No accountant approval required. NG-only — there is no legacy file-drop flow for projects today. |
| Currency Import | n/a (inbound) | — | Abacus-initiated; no SF-side verification gate. |

**Where the verification status is visible**:

- The existing formula field [Invoice__c.AbacusStatus__c](force-app/main/default/objects/Invoice__c/fields/AbacusStatus__c.field-meta.xml) (`READY` → `SELECTED TO TRANSFER` → `TRANSFERRED`) is **not modified**. It continues to read the existing `AbacusInterfaceExport__c` and `AbacusTransfer__c` fields, which the legacy path still stamps. While both paths are live, the formula reflects the legacy path's state.
- A parallel formula field could be added later for NG-path visibility if finance wants it (e.g., `Invoice__c.AbacusStatusNG__c` reading `AbacusInterfaceExport__c` + `AbacusNGTransfer__c`). Not in initial scope.

**Reverting a verification**: if the accountant unticks the verification field before Mule has picked up the row (i.e. row is still `Pending`), a small companion flow on the source record moves the NG row to `Cancelled` so Mule's PE consumer drops it.

## Target Architecture

```
   Source record (Account / Invoice / Project / …)
        │
        │  (accounting team flips verification checkbox, or project auto-fires)
        │
        ├─── existing legacy flow ──► AbacusInterface__c row ──► file drop on UNC share
        │                                                           │
        │                                                           └─► legacy middleware (Talend)
        │                                                                    │
        │                                                              [Live | Off per-InterfaceType]
        │                                                                    │
        │                                                                    └─► Abacus (file-based)
        │
        └─── new parallel flow ───► AbacusTransferNG__c row
                                          │
                                          └─► record-triggered flow on NG (after-insert)
                                                       │
                                                       └─► PE AbacusTransferNGQueued__e
                                                                  │
                                                                  ▼
                                                              MuleSoft
                                                                  │
                                                             [Dormant | Live per-InterfaceType]
                                                                  │
                                                          ┌───────┴────────┐
                                                          │                │
                                                       Dormant            Live
                                                          │                │
                                                     log only      call Abacus REST
                                                                          │
                                                                    PATCH NG row
                                                                    (Status / errors / doc id)
                                                                          │
                                                                    + PATCH Invoice.AbacusNGTransfer__c
                                                                      (Invoice Export only)
                                                                            │
                                                                            └─► new finalisation flow
                                                                                sets InvoiceStatus__c='Sent'
```

The two paths never read each other's state. Cutover for any `InterfaceType__c` is the coordinated ops gesture of (a) turning off the legacy middleware for that folder, and (b) flipping Mule to `Live` for that type. Rollback reverses both.

## New Object: `AbacusTransferNG__c`

Auto-number `Name`: `ABNG-{0000000}`. `sharingModel = Private`.

| API name | Type | Purpose |
|---|---|---|
| `InterfaceType__c` | Picklist | Seven values: Account Debtor Upsert / Account Supplier Upsert / Invoice Export / Cancellation Export / Staff Hour Export / Currency Import / **Project Export** (NG-only). |
| `Direction__c` | Picklist (`Outbound`, `Inbound`) | `Outbound` for SF→Abacus, `Inbound` for Abacus→SF. |
| `Status__c` | Picklist | `Dormant` (Mule is Dormant for this type — row sits until cutover and is then promoted to Pending via the Replay action), `Pending`, `InFlight`, `Sent`, `Failed`, `DeadLettered`, `Cancelled` (accountant unchecked verification before pickup). |
| `SourceObject__c` | Text(80) | API name of the source SObject, e.g. `Invoice__c`. |
| `SourceRecordId__c` | Text(18), Indexed | Id of the source record. |
| `Account__c` | Lookup(Account) | Populated when relevant. |
| `Invoice__c` | Lookup(Invoice__c) | Populated for Invoice Export / Cancellation Export. |
| `SupplierInvoice__c` | Lookup(SupplierInvoice__c) | Populated for inbound supplier invoices. |
| `SupplierCosts__c` | Lookup(SupplierCosts__c) | Populated for supplier-cost imports. |
| `Project__c` | Lookup(Project__c) | Populated for Project Export and for Staff Hour Export when scoped to a project. |
| `IdempotencyKey__c` | Text(40), External Id, Unique | Defaults to `Name`. Passed to Abacus via `Idempotency-Key` header. |
| `MuleCorrelationId__c` | Text(64) | Mule transaction id, written on callback. |
| `AbacusDocumentId__c` | Text(64) | External id assigned by Abacus on success. |
| `LastHttpStatus__c` | Number(3,0) | HTTP code from the last Mule → Abacus attempt. |
| `LastError__c` | Long Text Area | Error message body from Mule. |
| `LastAttemptAt__c` | DateTime | When Mule last tried. |
| `RetryCount__c` | Number(3,0) | Incremented by Mule on each retry. |
| `SentAt__c` | DateTime | Stamped when `Status__c` → `Sent`. |
| `PayloadSnapshot__c` | Long Text Area | Optional; capture the transformed payload at queue time for audit. |

## New Field on Invoice

| API name | Type | Purpose |
|---|---|---|
| `Invoice__c.AbacusNGTransfer__c` | DateTime | NG-only finalisation stamp. Mule writes this on success for Invoice Export. The new finalisation flow watches it and sets `InvoiceStatus__c = 'Sent'`. Separate from the existing `Invoice__c.AbacusTransfer__c` field, which the legacy path keeps using. |

## Platform Event

`AbacusTransferNGQueued__e` — **HighVolume**, PublishImmediately. Fired by a record-triggered flow on `AbacusTransferNG__c` (after-insert) when `Status__c = 'Pending'`. (Dormant rows do not publish — they sit until promoted to Pending via the Replay action after Mule cutover.) Carries:

- `AbacusTransferNGId__c` (Text 18)
- `InterfaceType__c` (Text 80)
- `IdempotencyKey__c` (Text 40)

Mule's Salesforce connector subscribes to this PE.

## Salesforce-Side Changes (additive only)

### Source-record-triggered flows (all new)

For each source object, a NEW record-triggered flow fires on the same conditions as the corresponding legacy flow (read for parity, never modified). Each flow creates a single `AbacusTransferNG__c` row.

- `RTF_Account_AbacusTransferNG_Debtor` — entry conditions mirror [AbacusInterfaceAccountUpsert.flow-meta.xml](force-app/main/default/flows/AbacusInterfaceAccountUpsert.flow-meta.xml).
- `RTF_Account_AbacusTransferNG_Supplier` — mirrors [AbacusInterfaceAccountUpsertSupplier.flow-meta.xml](force-app/main/default/flows/AbacusInterfaceAccountUpsertSupplier.flow-meta.xml).
- `RTF_Invoice_AbacusTransferNG` — fires on [Invoice__c.AbacusInterfaceExport__c](force-app/main/default/objects/Invoice__c/fields/AbacusInterfaceExport__c.field-meta.xml) flipping true.
- `RTF_Invoice_AbacusTransferNG_Cancellation` — fires on cancellation-invoice export-flag transitions.
- `RTF_Project_AbacusTransferNG` — fires on Project create + relevant Abacus-field updates. NG-only.
- `RTF_Invoice_AbacusTransferNG_Cancel` / `RTF_Account_AbacusTransferNG_Cancel` — fire when the verification flag flips back to false while a `Pending` NG row exists; sets the NG row's `Status__c = 'Cancelled'`.

Each new flow defaults its NG row to `Status__c = 'Pending'` unless an org-level switch indicates a desire to create rows in `Dormant` (separate operational choice, not in initial scope).

### NG row publish flow (new)

- `RTF_AbacusTransferNG_PublishPE` — record-triggered on `AbacusTransferNG__c` (after-insert), publishes `AbacusTransferNGQueued__e` when `Status__c = 'Pending'`. Flow-native PE publish; no Apex required.

### Invoice finalisation flow (new)

- `RTF_Invoice_AbacusNGTransfer_Finalise` — record-triggered on Invoice when `AbacusNGTransfer__c` becomes non-null. Sets `InvoiceStatus__c = 'Sent'`. NG counterpart to the legacy [InvoiceStatusSentToAbacusWhenTransferDateNotNull.flow-meta.xml](force-app/main/default/flows/InvoiceStatusSentToAbacusWhenTransferDateNotNull.flow-meta.xml). Both flows can fire safely on the same Invoice — whichever path stamps first wins; the second is a no-op because `InvoiceStatus__c` is already `Sent`.

### Inbound (Currency Import, SupplierInvoice)

New Apex REST resource `/services/apexrest/abacus/v1/inbound`. The endpoint:

1. Validates the `Idempotency-Key` header — if a `AbacusTransferNG__c` row already exists with that key, returns the original response.
2. Creates an `AbacusTransferNG__c` row with `Direction__c = 'Inbound'`, `Status__c = 'Sent'`, `SentAt__c = now`.
3. Upserts the target record (Currency / SupplierInvoice / SupplierCosts) in the same transaction.
4. Returns `{ abacusTransferNGId, status }`.

The legacy inbound file-drop reader is untouched. While both paths are running, an InterfaceType is either Live in Mule (inbound goes via REST) or Live on the legacy middleware (inbound goes via file drop) — never both simultaneously per the ops cutover gesture.

### Staff Hour Export (new parallel batch)

The legacy Staff Hour Export is a scheduled Apex batch (location TBC). A new batch `AbacusTransferNGStaffHourBatch` runs on the same cadence with the same aggregation rules but writes `AbacusTransferNG__c` rows instead of `AbacusInterface__c` rows. Both batches run in parallel.

### What is NOT changed on Salesforce

- `AbacusInterface__c` — schema, fields, statuses, picklist values, layouts, sharing rules, tab, topicsForObjects, sharing rules, validation rules: **untouched.**
- All `Abacus*.flow-meta.xml` flows: **untouched.**
- All `Abacus*` fields on Account, Invoice, SupplierInvoice, SupplierCosts, Project, Time, Contact: **untouched.**
- Custom metadata `Field.Account_AbacusDebtor`, `Field.Account_AbacusSupplier`, `ParentObjectUpdate.Invoice2Account_AbacusDebtor`: **untouched.**
- `Invoice__c.AbacusStatus__c` formula (READY / SELECTED TO TRANSFER / TRANSFERRED): **untouched** — keeps reading the legacy fields.
- Duplicate rule on `SupplierCosts__c`: **untouched.**
- The UNC share `\\BLC-ABA-01\SkywalkAbacusIntegration\...` and the legacy Talend middleware: **untouched** until ops disable them per-InterfaceType at cutover.
- [Application.cls](force-app/main/default/classes/Application.cls), [TestFactory.cls](force-app/main/default/classes/TestFactory.cls), all existing page layouts, all existing permission sets: **untouched.**

## MuleSoft-Side Responsibilities

1. **Subscribe** to `AbacusTransferNGQueued__e` via the Salesforce connector. Each event → one job.
2. **Read Mule's per-InterfaceType config**: `Dormant` or `Live`. If Dormant, log the message and stop (do not call Abacus, do not PATCH SF — the NG row stays `Pending` until manual cutover/Replay).
3. **Fetch** the `AbacusTransferNG__c` row and the related source record (resolved via `SourceObject__c` + `SourceRecordId__c`) in one or two SOQL calls. If `Status__c` has become `Cancelled` between PE publish and Mule fetch, drop the message.
4. **Set `Status__c = 'InFlight'`** and `LastAttemptAt__c = now` via a single SF REST PATCH.
5. **Transform** with DataWeave into the Abacus REST payload. One DataWeave module per `InterfaceType__c`. Optionally write the transformed payload to `PayloadSnapshot__c` for audit.
6. **Call Abacus** with header `Idempotency-Key: {IdempotencyKey__c}`. Use `until-successful` for retry; on terminal failure, push to DLQ (Anypoint MQ).
7. **Callback to Salesforce** (SF REST PATCH on `AbacusTransferNG__c` keyed by `IdempotencyKey__c`):
   - On 2xx: `Status__c = 'Sent'`, `AbacusDocumentId__c`, `LastHttpStatus__c`, `MuleCorrelationId__c`, `SentAt__c`. For Invoice Export, **additionally** PATCH `Invoice__c.AbacusNGTransfer__c = now` so the new finalisation flow finalises the invoice.
   - On terminal failure: `Status__c = 'Failed'`, `LastHttpStatus__c`, `LastError__c`, `RetryCount__c`.
   - On DLQ: `Status__c = 'DeadLettered'`.
8. **Named Credentials** for the Salesforce callback (Mule → SF) live in Mule's secure properties via a connected app and service user. The Salesforce → Abacus credentials never leave Mule.

The legacy mapping CMDT (`Field.Account_AbacusDebtor` etc.) is **not** consumed by Mule; DataWeave owns the NG-path mapping. The CMDT rows stay untouched as documentation/legacy.

## Status Lifecycle

```
   Legacy path (AbacusInterface__c) — unchanged
   ┌─────────────────────────────────────────────────────┐
   │  Prepared → Queued → Finished (No Errors|With Err.) │
   └─────────────────────────────────────────────────────┘

   NG path (AbacusTransferNG__c)
   ┌─────────────────────────────────────────────────────┐
   │  Dormant ─► (manual promote via Replay) ─► Pending  │
   │                                              │      │
   │                                              ▼      │
   │                                          InFlight   │
   │                                          │  │       │
   │                                          ▼  └► Sent │
   │                                       Failed        │
   │                                          │          │
   │                                          ▼          │
   │                                     DeadLettered    │
   │                                                     │
   │  Pending ─► Cancelled (verification untick by user) │
   └─────────────────────────────────────────────────────┘
```

The two object lifecycles are completely independent. Reports filter on the relevant object.

## Idempotency

- `IdempotencyKey__c` defaults to the auto-number `Name`. `External Id + Unique` means a re-published Platform Event can't create a duplicate outbox row.
- Mule sends `Idempotency-Key` header on every Abacus call. Abacus must treat duplicate keys as no-ops returning the original response — hard requirement on the Abacus REST contract.
- On Salesforce callback, Mule PATCHes by `IdempotencyKey__c` (External Id upsert), so even if a callback retries, the row converges.
- Inbound: the Apex REST endpoint also keys on `Idempotency-Key`, so Mule retrying an inbound delivery doesn't double-insert.

## Error Handling & Retries

- **Retries live in Mule**, not Salesforce. Apex never reschedules.
- Mule retry policy: exponential backoff, e.g. 1m / 5m / 30m / 2h / 12h, then DLQ.
- DLQ alerts go to the integrations channel (Slack / email — TBD with ops).
- Salesforce list view "Abacus NG — Failed / DeadLettered" filters on `Status__c`. Manual replay = a button on the layout backed by `AbacusTransferNGReplayAction` (`@InvocableMethod`): resets `Status__c = 'Pending'`, clears `LastError__c` / `LastHttpStatus__c` / `RetryCount__c`, publishes a fresh `AbacusTransferNGQueued__e` via `EventBus.publish()`.

## Migration / Cutover Plan

Cutover happens per `InterfaceType__c`. The Salesforce side is unchanged throughout — both paths emit in parallel from day one. Cutover is two coordinated ops gestures, neither in Salesforce metadata.

| Phase | Action | Risk |
|---|---|---|
| 1. Deploy NG schema, flows, Apex | All additive; legacy path is untouched. Mule is Dormant for all InterfaceTypes. NG rows accumulate as the same source events fire. | None — no runtime behaviour change for the legacy path. |
| 2. Deploy Mule app | Mule subscribes to the PE channel. All InterfaceTypes start Dormant. NG rows remain at `Pending` in Salesforce but Mule logs only. | None. |
| 3. Cut over `Currency Import` | Ops disables the legacy middleware's Currency Import folder polling; ops flips Mule's Currency Import config to Live. NG inbound REST endpoint receives Currency from Abacus. | Low — currency is read-mostly. |
| 4. Cut over `Account Debtor Upsert` and `Account Supplier Upsert` | Same pattern. Existing NG `Pending` rows can be promoted via Replay; new rows go straight through. | Low — upserts are idempotent. |
| 5. Cut over `SupplierCosts` / `SupplierInvoice` / `Staff Hour Export` | Same pattern. For Staff Hour, the legacy and NG batches both run on every schedule — at cutover, ops disables the legacy batch's schedule (or its middleware consumer of the resulting file). | Medium — supplier-cost reconciliation matters. |
| 6. Cut over `Invoice Export` and `Cancellation Export` last | Highest-impact. Coordinate with finance, avoid month-end. Promote backlogged `Pending` NG rows in a controlled batch. | Medium-High — finance reconciliation. |
| 7. `Project Export` | Enable from the start (NG-only, no legacy equivalent). | Low — additive functionality. |
| 8. Decommission later (out of scope) | After several closed months entirely on NG with no rollbacks, separately decide whether to retire the file-drop machinery. **Explicitly out of scope.** | — |

Rollback at any phase: ops re-enables the legacy middleware for that InterfaceType and flips Mule back to Dormant. The Salesforce side never changes — both paths keep emitting throughout. Replay rows in `Pending` state at the moment of rollback either ride through Mule (if its still Live at that moment) or stay until Mule is flipped back.

## Open Questions / Decisions

- **Abacus REST contract**: who owns the OpenAPI spec? Need confirmation that Abacus honours `Idempotency-Key` semantics. If not, idempotency must be enforced inside Mule (lookup-before-write) — slower and not bulletproof.
- **Auth Mule ↔ Abacus**: OAuth 2.0 client credentials assumed. Confirm with Abacus admin.
- **Auth Mule ↔ Salesforce**: connected app + JWT bearer for Mule, scoped to a service user with permission set granting only the minimum: read on source objects, CRUD on `AbacusTransferNG__c`, edit on `Invoice__c.AbacusNGTransfer__c` (the NG-only field — *not* the legacy `Invoice__c.AbacusTransfer__c`).
- **Volume**: current peak rows/day on `AbacusInterface__c` → sizes the Mule worker tier and decides Anypoint MQ vs VM queue.
- **Replay window**: confirm Mule DLQ retention matches finance's reconciliation window (typically 90 days for month-end close).
- **Initial Dormant rows**: do we want the NG row default to be `Dormant` or `Pending`? Current plan: default `Pending`; while Mule is Dormant for that InterfaceType, Mule consumes the PE but no-ops. Alternative: default `Dormant` and rely on a Replay step at cutover. Decided: default `Pending` (simpler; backlog stays in Mule, not in Salesforce).

## What Stays Untouched

- `AbacusInterface__c` object — schema, fields, layouts, sharing rules, tab, topicsForObjects: untouched.
- `Status__c` picklist on `AbacusInterface__c`: no new values, no relabels.
- The UNC share `\\BLC-ABA-01\SkywalkAbacusIntegration\...` and whatever middleware reads it: untouched until ops disables per-InterfaceType at cutover.
- Custom metadata `Field.Account_AbacusDebtor`, `Field.Account_AbacusSupplier`, `ParentObjectUpdate.Invoice2Account_AbacusDebtor`: untouched.
- Existing flows' logic (`AbacusInterfaceAccountUpsert`, `AbacusInterfaceAccountUpsertSupplier`, `InvoiceStatusSentToAbacusWhenTransferDateNotNull`, `PackageSupplierCostsAbacusInbox`, all `RTF_*` Abacus flows): unchanged.
- Duplicate rule on `SupplierCosts__c.Supplier_Cost_Abacus_Doc_Nr_Pos_Nr`: untouched.
- Invoice formula field `AbacusStatus__c` (READY / SELECTED TO TRANSFER / TRANSFERRED): untouched — still reflects legacy state via the existing `AbacusTransfer__c` field.
- All `Abacus*` fields on Account, Invoice, SupplierInvoice, SupplierCosts, Project, Contact, Time: untouched.
- `Application.cls`, `TestFactory.cls`, all existing page layouts, all existing permission sets, all existing connected apps: untouched.
