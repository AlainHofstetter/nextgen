public with sharing class AbacusTransferNGApprovalSummaryAction {

    // Only outbound rows still awaiting approval can be bulk-approved. Everything else
    // (already Sent/InFlight, Failed, Cancelled, and all inbound audit rows) is filtered
    // out here so the confirm screen only ever summarizes rows the approver can actually act on.
    private static final String ELIGIBLE_STATUS = 'PendingApproval';
    private static final String ELIGIBLE_DIRECTION = 'Outbound';

    // Bucket label used when an invoice has no ProjectCostCenter__c; always sorted last.
    @TestVisible
    private static final String NO_COST_CENTER_LABEL = '(no cost center)';

    @InvocableMethod(label='Abacus Transfer NG Approval Summary' description='Given the selected AbacusTransferNG__c rows, resolves which are eligible for bulk approval (outbound rows in PendingApproval) and builds an HTML summary of the referenced invoices\' CHF amounts (net/gross) grouped by cost center. Distinct invoices are counted once even when several rows reference the same invoice. Returns exactly one result per request.')
    public static List<Result> summarize(List<Request> requests) {
        List<Set<Id>> idsPerRequest = new List<Set<Id>>();
        Set<Id> allIds = new Set<Id>();
        for (Request r : requests) {
            Set<Id> ids = new Set<Id>();
            if (r.abacusTransferNGIds != null) ids.addAll(r.abacusTransferNGIds);
            idsPerRequest.add(ids);
            allIds.addAll(ids);
        }

        // One SOQL for the whole invocation; the eligibility filter is applied in the query
        // so per-request filtering below only has to intersect Ids with what came back.
        Map<Id, AbacusTransferNG__c> eligibleById = new Map<Id, AbacusTransferNG__c>();
        if (!allIds.isEmpty()) {
            eligibleById.putAll([
                SELECT Id, Invoice__c,
                       Invoice__r.InvoiceTotalAmountNetCHF__c,
                       Invoice__r.InvoiceTotalAmountGrossCHF__c,
                       Invoice__r.ProjectCostCenter__c,
                       Invoice__r.ProjectCostCenter__r.Name,
                       Invoice__r.ProjectCostCenter__r.CostCenterNr__c
                FROM AbacusTransferNG__c
                WHERE Id IN :allIds
                  AND Status__c = :ELIGIBLE_STATUS
                  AND Direction__c = :ELIGIBLE_DIRECTION
            ]);
        }

        List<Result> results = new List<Result>();
        for (Set<Id> ids : idsPerRequest) {
            // Preserve query order (Map.values()) but keep only the Ids this request asked for.
            List<AbacusTransferNG__c> rows = new List<AbacusTransferNG__c>();
            for (AbacusTransferNG__c row : eligibleById.values()) {
                if (ids.contains(row.Id)) rows.add(row);
            }
            results.add(buildResult(rows));
        }
        return results;
    }

    // The aggregation core, kept package-visible so it can be unit-tested with in-memory rows
    // (invoice/cost-center formula fields are set via JSON.deserialize in the test).
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

        // Group the deduped invoices by cost center, summing net/gross (null treated as 0).
        Map<String, CostCenterGroup> groupsByLabel = new Map<String, CostCenterGroup>();
        Decimal grandNet = 0;
        Decimal grandGross = 0;
        for (Invoice__c inv : invoicesById.values()) {
            String label = groupLabel(inv);
            CostCenterGroup grp = groupsByLabel.get(label);
            if (grp == null) {
                grp = new CostCenterGroup(label);
                groupsByLabel.put(label, grp);
            }
            Decimal net = inv.InvoiceTotalAmountNetCHF__c == null ? 0 : inv.InvoiceTotalAmountNetCHF__c;
            Decimal gross = inv.InvoiceTotalAmountGrossCHF__c == null ? 0 : inv.InvoiceTotalAmountGrossCHF__c;
            grp.net += net;
            grp.gross += gross;
            grandNet += net;
            grandGross += gross;
        }

        // Sort labels alphabetically, then force the "(no cost center)" bucket to the end.
        List<String> labels = new List<String>(groupsByLabel.keySet());
        labels.sort();
        Boolean hasNoCostCenter = groupsByLabel.containsKey(NO_COST_CENTER_LABEL);
        if (hasNoCostCenter) {
            labels.remove(labels.indexOf(NO_COST_CENTER_LABEL));
        }

        String html = '<p><b>Invoice amounts by cost center (CHF)</b> — '
            + result.invoiceCount + ' invoice(s):</p><ul>';
        for (String label : labels) {
            html += groupLine(groupsByLabel.get(label));
        }
        if (hasNoCostCenter) {
            html += groupLine(groupsByLabel.get(NO_COST_CENTER_LABEL));
        }
        html += '</ul><p><b>Total</b>: Net ' + formatCHF(grandNet)
            + ' / Gross ' + formatCHF(grandGross) + '</p>';
        result.summaryHtml = html;
        return result;
    }

    // Label for the cost-center group of a single invoice, already HTML-escaped.
    private static String groupLabel(Invoice__c inv) {
        if (inv.ProjectCostCenter__c == null || inv.ProjectCostCenter__r == null) {
            return NO_COST_CENTER_LABEL;
        }
        // Escape the user-controlled Nr/Name parts only; the en dash separator is injected
        // unescaped so it renders as a real "–" rather than an &ndash; entity.
        String nr = inv.ProjectCostCenter__r.CostCenterNr__c;
        String ccName = inv.ProjectCostCenter__r.Name;
        return (nr == null ? '' : nr.escapeHtml4())
            + ' – '
            + (ccName == null ? '' : ccName.escapeHtml4());
    }

    // The label is already escaped for real cost centers; the "(no cost center)" literal is safe.
    private static String groupLine(CostCenterGroup grp) {
        return '<li><b>' + grp.label + '</b>: Net ' + formatCHF(grp.net)
            + ' / Gross ' + formatCHF(grp.gross) + '</li>';
    }

    // Swiss amount formatting with apostrophe thousands separators and exactly two decimals.
    // Hand-rolled because Decimal.format() is locale-dependent and drops trailing zeros.
    @TestVisible
    private static String formatCHF(Decimal value) {
        if (value == null) return '0.00';
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
        if (decPart.length() == 1) decPart += '0';
        else if (decPart.length() == 0) decPart = '00';
        else if (decPart.length() > 2) decPart = decPart.substring(0, 2);

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

    // Simple mutable accumulator for one cost-center group.
    private class CostCenterGroup {
        String label;
        Decimal net = 0;
        Decimal gross = 0;
        CostCenterGroup(String label) {
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
        @InvocableVariable(label='HTML summary of invoice amounts by cost center')
        public String summaryHtml;
    }
}
