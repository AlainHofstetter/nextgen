public with sharing class AbacusTransferNGApprovalSummaryAction {
  // Only outbound rows still awaiting approval can be bulk-approved. Everything else
  // (already Sent/InFlight, Failed, Cancelled, and all inbound audit rows) is filtered
  // out here so the confirm screen only ever summarizes rows the approver can actually act on.
  private static final String ELIGIBLE_STATUS = 'PendingApproval';
  private static final String ELIGIBLE_DIRECTION = 'Outbound';

  // Bucket label used when an invoice has no BillingViaCompany__c legal entity; always sorted last.
  @TestVisible
  private static final String NO_LEGAL_ENTITY_LABEL = '(no legal entity)';

  @InvocableMethod(
    label='Abacus Transfer NG Approval Summary'
    description='Given the selected AbacusTransferNG__c rows, resolves which are eligible for bulk approval (outbound rows in PendingApproval) and builds an HTML summary of the referenced invoices\' CHF amounts (net/gross) grouped by legal entity (billing company). Distinct invoices are counted once even when several rows reference the same invoice. Returns exactly one result per request.'
  )
  public static List<Result> summarize(List<Request> requests) {
    List<Set<Id>> idsPerRequest = new List<Set<Id>>();
    Set<Id> allIds = new Set<Id>();
    for (Request r : requests) {
      Set<Id> ids = new Set<Id>();
      if (r.abacusTransferNGIds != null)
        ids.addAll(r.abacusTransferNGIds);
      idsPerRequest.add(ids);
      allIds.addAll(ids);
    }

    // One SOQL for the whole invocation; the eligibility filter is applied in the query
    // so per-request filtering below only has to intersect Ids with what came back.
    Map<Id, AbacusTransferNG__c> eligibleById = new Map<Id, AbacusTransferNG__c>();
    if (!allIds.isEmpty()) {
      eligibleById.putAll(
        [
          SELECT
            Id,
            Invoice__c,
            Invoice__r.InvoiceTotalAmountNetCHF__c,
            Invoice__r.InvoiceTotalAmountGrossCHF__c,
            Invoice__r.InvoiceTotalAmountNet__c,
            Invoice__r.InvoiceTotalAmountGross__c,
            Invoice__r.CurrencyRateToCHF__c,
            Invoice__r.BillingViaCompany__c,
            Invoice__r.BillingViaCompany__r.Name,
            Invoice__r.BillingViaCompany__r.LegalCode__c
          FROM AbacusTransferNG__c
          WHERE
            Id IN :allIds
            AND Status__c = :ELIGIBLE_STATUS
            AND Direction__c = :ELIGIBLE_DIRECTION
        ]
      );
    }

    List<Result> results = new List<Result>();
    for (Set<Id> ids : idsPerRequest) {
      // Preserve query order (Map.values()) but keep only the Ids this request asked for.
      List<AbacusTransferNG__c> rows = new List<AbacusTransferNG__c>();
      for (AbacusTransferNG__c row : eligibleById.values()) {
        if (ids.contains(row.Id))
          rows.add(row);
      }
      results.add(buildResult(rows));
    }
    return results;
  }

  // The aggregation core, kept package-visible so it can be unit-tested with in-memory rows
  // (invoice/legal-entity formula fields are set via JSON.deserialize in the test).
  @TestVisible
  private static Result buildResult(List<AbacusTransferNG__c> rows) {
    Result result = new Result();
    result.eligibleIds = new List<Id>();
    for (AbacusTransferNG__c row : rows) {
      result.eligibleIds.add(row.Id);
    }
    result.eligibleCount = rows.size();

    // Dedupe invoices: several NG rows may point at the same invoice, but each invoice
    // must be counted and summed exactly once.
    Map<Id, Invoice__c> invoicesById = new Map<Id, Invoice__c>();
    for (AbacusTransferNG__c row : rows) {
      if (row.Invoice__c != null && row.Invoice__r != null) {
        invoicesById.put(row.Invoice__c, row.Invoice__r);
      }
    }
    result.invoiceCount = invoicesById.size();

    if (invoicesById.isEmpty()) {
      // No invoices among the eligible rows: nothing to summarize.
      result.summaryHtml = null;
      return result;
    }

    // Group the deduped invoices by legal entity, summing net/gross (null treated as 0).
    // Keyed by groupSortKey (a zero-padded numeric key) so keys.sort() orders the groups
    // numerically by legal code; each group carries its own display label for rendering.
    Map<String, LegalEntityGroup> groupsByKey = new Map<String, LegalEntityGroup>();
    Decimal grandNet = 0;
    Decimal grandGross = 0;
    for (Invoice__c inv : invoicesById.values()) {
      String key = groupSortKey(inv);
      LegalEntityGroup grp = groupsByKey.get(key);
      if (grp == null) {
        grp = new LegalEntityGroup(groupLabel(inv));
        groupsByKey.put(key, grp);
      }
      // Positions' CHF rates aren't reliably copied down from the invoice header (a
      // separate broken flow), so the *CHF__c formulas can read 0 even for real invoices.
      // The header's CurrencyRateToCHF__c is authoritative, so prefer document total x
      // header rate and only fall back to the stored CHF formula when there is no rate.
      Decimal net = chfAmount(
        inv.InvoiceTotalAmountNet__c,
        inv.CurrencyRateToCHF__c,
        inv.InvoiceTotalAmountNetCHF__c
      );
      Decimal gross = chfAmount(
        inv.InvoiceTotalAmountGross__c,
        inv.CurrencyRateToCHF__c,
        inv.InvoiceTotalAmountGrossCHF__c
      );
      grp.net += net;
      grp.gross += gross;
      grandNet += net;
      grandGross += gross;
    }

    // Sort keys (zero-padded numeric), then force the "(no legal entity)" bucket to the end.
    // The no-entity group's key equals the label sentinel exactly, so the remove-and-append
    // pattern transfers 1:1 from the old label-keyed logic.
    List<String> keys = new List<String>(groupsByKey.keySet());
    keys.sort();
    Boolean hasNoLegalEntity = groupsByKey.containsKey(NO_LEGAL_ENTITY_LABEL);
    if (hasNoLegalEntity) {
      keys.remove(keys.indexOf(NO_LEGAL_ENTITY_LABEL));
    }

    String html =
      '<p><b>Invoice amounts by legal entity (CHF)</b> — ' +
      result.invoiceCount +
      ' invoice(s):</p><ul>';
    for (String key : keys) {
      html += groupLine(groupsByKey.get(key));
    }
    if (hasNoLegalEntity) {
      html += groupLine(groupsByKey.get(NO_LEGAL_ENTITY_LABEL));
    }
    html +=
      '</ul><p><b>Total</b>: Net ' +
      formatCHF(grandNet) +
      ' / Gross ' +
      formatCHF(grandGross) +
      '</p>';
    result.summaryHtml = html;
    return result;
  }

  // Converts a document-currency amount to CHF using the invoice header's CurrencyRateToCHF__c.
  // The header rate is reliable (it's 1 for CHF invoices); the per-position CHF formulas are
  // not, because an unrelated broken flow never copies the rate down to invoice positions.
  // When no header rate is available at all, fall back to the stored (org-canonical) CHF
  // formula value so behavior for edge cases (e.g. bare/legacy records) is unchanged.
  @TestVisible
  private static Decimal chfAmount(
    Decimal documentAmount,
    Decimal rate,
    Decimal storedChf
  ) {
    if (rate != null) {
      return (documentAmount == null ? 0 : documentAmount) * rate;
    }
    return storedChf == null ? 0 : storedChf;
  }

  // True when an invoice has no resolvable legal entity (missing company or missing code).
  private static Boolean isNoLegalEntity(Invoice__c inv) {
    return inv.BillingViaCompany__c == null ||
      inv.BillingViaCompany__r == null ||
      inv.BillingViaCompany__r.LegalCode__c == null;
  }

  // Map key for the legal-entity group of a single invoice. No-entity rows use the label
  // sentinel; real entities use a zero-padded numeric key so keys.sort() then orders
  // 10 < 25 < 100 numerically (a plain alphabetical sort would give 10, 100, 25).
  private static String groupSortKey(Invoice__c inv) {
    if (isNoLegalEntity(inv)) {
      return NO_LEGAL_ENTITY_LABEL;
    }
    return String.valueOf(inv.BillingViaCompany__r.LegalCode__c.intValue())
        .leftPad(6, '0') +
      '|' +
      groupLabel(inv);
  }

  // Display label for the legal-entity group of a single invoice, already HTML-escaped.
  private static String groupLabel(Invoice__c inv) {
    if (isNoLegalEntity(inv)) {
      return NO_LEGAL_ENTITY_LABEL;
    }
    // intValue() on the code avoids Decimal scale artifacts (e.g. "25" not "25.0"). Escape
    // the user-controlled Name only; the en dash separator is injected unescaped so it
    // renders as a real "–" rather than an &ndash; entity. Result e.g. "25 – gateB AG".
    String code = String.valueOf(
      inv.BillingViaCompany__r.LegalCode__c.intValue()
    );
    String companyName = inv.BillingViaCompany__r.Name;
    return code +
      ' – ' +
      (companyName == null ? '' : companyName.escapeHtml4());
  }

  // The label is already escaped for real legal entities; the "(no legal entity)" literal is safe.
  private static String groupLine(LegalEntityGroup grp) {
    return '<li><b>' +
      grp.label +
      '</b>: Net ' +
      formatCHF(grp.net) +
      ' / Gross ' +
      formatCHF(grp.gross) +
      '</li>';
  }

  // Swiss amount formatting with apostrophe thousands separators and exactly two decimals.
  // Hand-rolled because Decimal.format() is locale-dependent and drops trailing zeros.
  @TestVisible
  private static String formatCHF(Decimal value) {
    if (value == null)
      return '0.00';
    Decimal scaled = value.setScale(2, System.RoundingMode.HALF_UP);
    Boolean negative = scaled < 0;
    String digits = scaled.abs().toPlainString(); // e.g. "1234567.50"
    String intPart;
    String decPart;
    Integer dot = digits.indexOf('.');
    if (dot == -1) {
      intPart = digits;
      decPart = '00';
    } else {
      intPart = digits.substring(0, dot);
      decPart = digits.substring(dot + 1);
    }
    // Guarantee exactly two decimal places.
    if (decPart.length() == 1)
      decPart += '0';
    else if (decPart.length() == 0)
      decPart = '00';
    else if (decPart.length() > 2)
      decPart = decPart.substring(0, 2);

    // Insert apostrophe separators every three digits from the right of the integer part.
    String grouped = '';
    Integer count = 0;
    for (Integer i = intPart.length() - 1; i >= 0; i--) {
      grouped = intPart.substring(i, i + 1) + grouped;
      count++;
      if (count == 3 && i > 0) {
        grouped = '\'' + grouped;
        count = 0;
      }
    }

    return (negative ? '-' : '') + grouped + '.' + decPart;
  }

  // Simple mutable accumulator for one legal-entity group.
  private class LegalEntityGroup {
    String label;
    Decimal net = 0;
    Decimal gross = 0;
    LegalEntityGroup(String label) {
      this.label = label;
    }
  }

  public class Request {
    @InvocableVariable(label='Selected AbacusTransferNG Ids' required=true)
    public List<Id> abacusTransferNGIds;
  }

  public class Result {
    @InvocableVariable(label='Ids eligible for bulk approval')
    public List<Id> eligibleIds;
    @InvocableVariable(label='Number of eligible rows')
    public Integer eligibleCount;
    @InvocableVariable(label='Number of distinct invoices')
    public Integer invoiceCount;
    @InvocableVariable(label='HTML summary of invoice amounts by legal entity')
    public String summaryHtml;
  }
}
