/**
 * Backs the header LWC on the Abacus Approvals app-page, exposing three org-wide KPIs
 * (rows awaiting approval, the total CHF gross of the invoices behind them, and the most
 * recent transfer timestamp).
 *
 * `without sharing` is deliberate: AbacusTransferNG__c has a Private OWD and its rows are
 * owned by the integration/flow users that create them, so an approver without Modify All
 * would otherwise see only the sliver of records shared to them. The KPIs must reflect the
 * org-wide truth, and only aggregate numbers are ever returned here — no record data leaks
 * out of this controller.
 */
public without sharing class AbacusTransferNGHeaderController {
  // Rows awaiting approval; the only status the header counts and sums invoices for.
  private static final String PENDING_STATUS = 'PendingApproval';
  // Statuses surfaced as "needs attention" on the header: stuck or exhausted transfers.
  private static final String FAILED_STATUS = 'Failed';
  private static final String DEAD_LETTERED_STATUS = 'DeadLettered';

  @AuraEnabled(cacheable=true)
  public static HeaderData getHeaderData() {
    HeaderData data = new HeaderData();

    // One GROUP BY Status__c aggregate feeds both the pending count and the needs-attention
    // count, so we don't fire a separate COUNT() per status.
    Map<String, Integer> counts = countByStatus();
    data.pendingCount = countFor(counts, PENDING_STATUS);
    data.needsAttentionCount =
      countFor(counts, FAILED_STATUS) + countFor(counts, DEAD_LETTERED_STATUS);

    List<AbacusTransferNG__c> pendingRows = [
      SELECT
        Invoice__c,
        Invoice__r.InvoiceTotalAmountGross__c,
        Invoice__r.InvoiceTotalAmountGrossCHF__c,
        Invoice__r.CurrencyRateToCHF__c
      FROM AbacusTransferNG__c
      WHERE Status__c = :PENDING_STATUS AND Invoice__c != NULL
    ];
    data.totalInvoiceGrossChf = sumGrossChf(pendingRows);

    // Distinct invoices behind the pending rows just queried; same dedupe semantics as
    // sumGrossChf (each invoice counted once), built inline to avoid a second SOQL.
    Set<Id> pendingInvoiceIds = new Set<Id>();
    for (AbacusTransferNG__c row : pendingRows) {
      if (row.Invoice__c != null) {
        pendingInvoiceIds.add(row.Invoice__c);
      }
    }
    data.pendingInvoiceCount = pendingInvoiceIds.size();

    AggregateResult mx = [
      SELECT MAX(SentAt__c) lastSent
      FROM AbacusTransferNG__c
    ];
    data.lastTransferAt = (Datetime) mx.get('lastSent');

    AggregateResult oldest = [
      SELECT MIN(CreatedDate) oldestCreated
      FROM AbacusTransferNG__c
      WHERE Status__c = :PENDING_STATUS
    ];
    data.oldestPendingCreatedAt = (Datetime) oldest.get('oldestCreated');

    return data;
  }

  // Feeds the per-status tab labels on the Abacus Approvals page: one row count per status,
  // keyed by the raw Status__c API value (e.g. 'PendingApproval', 'Failed'). Statuses with
  // no rows are absent from the map — callers treat a missing key as 0.
  @AuraEnabled(cacheable=true)
  public static Map<String, Integer> getStatusCounts() {
    return countByStatus();
  }

  // Shared GROUP BY Status__c aggregate: a status => row-count map, statuses with no rows
  // absent from the map. Backs both getStatusCounts() and getHeaderData().
  private static Map<String, Integer> countByStatus() {
    Map<String, Integer> counts = new Map<String, Integer>();
    for (AggregateResult ar : [
      SELECT Status__c s, COUNT(Id) c
      FROM AbacusTransferNG__c
      GROUP BY Status__c
    ]) {
      counts.put((String) ar.get('s'), (Integer) ar.get('c'));
    }
    return counts;
  }

  // A missing status key means zero rows for that status.
  private static Integer countFor(Map<String, Integer> counts, String status) {
    return counts.containsKey(status) ? counts.get(status) : 0;
  }

  // Sums the CHF gross of the invoices behind the given transfer rows, deduping invoices
  // (several rows can reference the same invoice — count each once). Mirrors the CHF
  // semantics of AbacusTransferNGApprovalSummaryAction.chfAmount(): the stored *CHF__c
  // formulas can read 0 for real invoices because per-position rates aren't copied down,
  // so the invoice header's CurrencyRateToCHF__c is authoritative. Per distinct invoice:
  // when a header rate is present, use gross x rate (null gross => 0); otherwise fall back
  // to the stored gross CHF formula (null => 0).
  @TestVisible
  private static Decimal sumGrossChf(List<AbacusTransferNG__c> rows) {
    Map<Id, Invoice__c> invoicesById = new Map<Id, Invoice__c>();
    for (AbacusTransferNG__c row : rows) {
      if (row.Invoice__c != null && row.Invoice__r != null) {
        invoicesById.put(row.Invoice__c, row.Invoice__r);
      }
    }

    Decimal total = 0;
    for (Invoice__c inv : invoicesById.values()) {
      if (inv.CurrencyRateToCHF__c != null) {
        Decimal gross = inv.InvoiceTotalAmountGross__c == null
          ? 0
          : inv.InvoiceTotalAmountGross__c;
        total += gross * inv.CurrencyRateToCHF__c;
      } else {
        total += inv.InvoiceTotalAmountGrossCHF__c == null
          ? 0
          : inv.InvoiceTotalAmountGrossCHF__c;
      }
    }
    return total;
  }

  public class HeaderData {
    @AuraEnabled
    public Integer pendingCount;
    @AuraEnabled
    public Decimal totalInvoiceGrossChf;
    @AuraEnabled
    public Datetime lastTransferAt;
    @AuraEnabled
    public Integer needsAttentionCount;
    @AuraEnabled
    public Datetime oldestPendingCreatedAt;
    @AuraEnabled
    public Integer pendingInvoiceCount;
  }
}
