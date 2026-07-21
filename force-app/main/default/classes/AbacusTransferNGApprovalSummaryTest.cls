@IsTest
private class AbacusTransferNGApprovalSummaryTest {

    // ---------------------------------------------------------------------------------------
    // In-memory helpers: formula fields (InvoiceTotalAmount*CHF__c) and nested relationship
    // objects (Invoice__r / ProjectCostCenter__r) are not directly assignable in Apex, so we
    // build the rows through JSON.deserialize which happily populates read-only fields.
    // ---------------------------------------------------------------------------------------

    private static Integer idCounter = 0;

    // Deterministic fake Id built from the sObject key prefix + a zero-padded counter.
    // 15-char form: the 18-char form carries a case checksum that plain digits would fail.
    private static Id fakeId(Schema.SObjectType sot) {
        idCounter++;
        String prefix = sot.getDescribe().getKeyPrefix();
        String suffix = String.valueOf(idCounter);
        return Id.valueOf(prefix + '0'.repeat(12 - suffix.length()) + suffix);
    }

    // Builds an AbacusTransferNG__c row (Id set) with an optional nested Invoice__r that carries
    // the stored CHF net/gross formula values (InvoiceTotalAmount*CHF__c) and an optional nested
    // ProjectCostCenter__r (nr + name). Kept as the original overload so existing call sites that
    // only care about the stored-CHF fallback path keep compiling unchanged; it delegates to the
    // full overload with null document amounts/rate, which is the null-rate fallback behavior.
    private static AbacusTransferNG__c buildRow(
        Id invoiceId, Decimal netChf, Decimal grossChf,
        Id costCenterId, String costCenterNr, String costCenterName
    ) {
        return buildRow(
            invoiceId, null, null, null, netChf, grossChf,
            costCenterId, costCenterNr, costCenterName
        );
    }

    // Full overload: also sets the document-currency totals and the header CurrencyRateToCHF__c
    // used by chfAmount() to derive CHF net/gross, alongside the stored CHF formula values that
    // now only serve as the fallback when no header rate is present.
    private static AbacusTransferNG__c buildRow(
        Id invoiceId, Decimal net, Decimal gross, Decimal rate, Decimal netChf, Decimal grossChf,
        Id costCenterId, String costCenterNr, String costCenterName
    ) {
        Map<String, Object> row = new Map<String, Object>();
        row.put('Id', fakeId(AbacusTransferNG__c.SObjectType));

        if (invoiceId != null) {
            Map<String, Object> inv = new Map<String, Object>();
            inv.put('Id', invoiceId);
            inv.put('InvoiceTotalAmountNetCHF__c', netChf);
            inv.put('InvoiceTotalAmountGrossCHF__c', grossChf);
            inv.put('InvoiceTotalAmountNet__c', net);
            inv.put('InvoiceTotalAmountGross__c', gross);
            inv.put('CurrencyRateToCHF__c', rate);
            if (costCenterId != null) {
                Map<String, Object> cc = new Map<String, Object>();
                cc.put('Id', costCenterId);
                cc.put('CostCenterNr__c', costCenterNr);
                cc.put('Name', costCenterName);
                inv.put('ProjectCostCenter__c', costCenterId);
                inv.put('ProjectCostCenter__r', cc);
            }
            row.put('Invoice__c', invoiceId);
            row.put('Invoice__r', inv);
        }

        return (AbacusTransferNG__c) JSON.deserialize(
            JSON.serialize(row), AbacusTransferNG__c.class
        );
    }

    // ---------------------------------------------------------------------------------------
    // buildResult unit tests
    // ---------------------------------------------------------------------------------------

    @IsTest
    static void buildResultGroupsAndDedupesInvoices() {
        Id cc1 = fakeId(CostCenter__c.SObjectType);
        Id cc2 = fakeId(CostCenter__c.SObjectType);
        Id invA = fakeId(Invoice__c.SObjectType);
        Id invB = fakeId(Invoice__c.SObjectType);

        // Two rows share invoice A (must count once); a third row references invoice B.
        // No header rate is set, so these exercise the stored-CHF fallback path (see
        // chfAmount()); the values below are set directly on InvoiceTotalAmount*CHF__c.
        AbacusTransferNG__c r1 = buildRow(invA, 12500, 13750, cc1, '100', 'Alpha');
        AbacusTransferNG__c r2 = buildRow(invA, 12500, 13750, cc1, '100', 'Alpha');
        AbacusTransferNG__c r3 = buildRow(invB, 500, 550, cc2, '200', 'Beta');
        List<AbacusTransferNG__c> rows = new List<AbacusTransferNG__c>{ r1, r2, r3 };

        AbacusTransferNGApprovalSummaryAction.Result res =
            AbacusTransferNGApprovalSummaryAction.buildResult(rows);

        Assert.areEqual(3, res.eligibleCount, 'all three rows are eligible');
        Assert.areEqual(3, res.eligibleIds.size());
        Assert.areEqual(r1.Id, res.eligibleIds[0], 'eligibleIds keep row order');
        Assert.areEqual(r3.Id, res.eligibleIds[2]);
        Assert.areEqual(2, res.invoiceCount, 'invoice A counted once despite two rows');

        String html = res.summaryHtml;
        Assert.isNotNull(html);
        Assert.isTrue(html.contains('2 invoice(s):'), 'header shows distinct invoice count');
        Assert.isTrue(
            html.contains('<li><b>100 – Alpha</b>: Net 12\'500.00 / Gross 13\'750.00</li>'),
            'Alpha group line: ' + html
        );
        Assert.isTrue(
            html.contains('<li><b>200 – Beta</b>: Net 500.00 / Gross 550.00</li>'),
            'Beta group line: ' + html
        );
        Assert.isTrue(
            html.contains('<p><b>Total</b>: Net 13\'000.00 / Gross 14\'300.00</p>'),
            'total line: ' + html
        );
        // Alpha sorts before Beta.
        Assert.isTrue(html.indexOf('100 – Alpha') < html.indexOf('200 – Beta'),
            'groups sorted alphabetically by label');
    }

    @IsTest
    static void buildResultConvertsUsingHeaderRateWhenPresent() {
        Id cc1 = fakeId(CostCenter__c.SObjectType);
        Id inv = fakeId(Invoice__c.SObjectType);

        // Document-currency totals converted via the header rate: 100 * 0.93 = 93.00 (exact),
        // 107.7 * 0.93 = 100.161 -> HALF_UP to 100.16. Stored CHF formulas are left null to
        // prove the conversion path (not the fallback) is what produced the result.
        AbacusTransferNG__c row = buildRow(
            inv, 100, 107.7, 0.93, null, null,
            cc1, '100', 'Alpha'
        );

        AbacusTransferNGApprovalSummaryAction.Result res =
            AbacusTransferNGApprovalSummaryAction.buildResult(
                new List<AbacusTransferNG__c>{ row }
            );

        String html = res.summaryHtml;
        Assert.isTrue(
            html.contains('<li><b>100 – Alpha</b>: Net 93.00 / Gross 100.16</li>'),
            'header-rate conversion with HALF_UP rounding: ' + html
        );
        Assert.isTrue(html.contains('<p><b>Total</b>: Net 93.00 / Gross 100.16</p>'));
    }

    @IsTest
    static void buildResultFallsBackToStoredChfWhenRateIsNull() {
        Id cc1 = fakeId(CostCenter__c.SObjectType);
        Id inv = fakeId(Invoice__c.SObjectType);

        // Document amounts are present but there is no header rate at all, so chfAmount()
        // must fall back to the stored (org-canonical) CHF formula values instead of
        // multiplying by a missing rate.
        AbacusTransferNG__c row = buildRow(
            inv, 100, 107.7, null, 55.55, 60.60,
            cc1, '100', 'Alpha'
        );

        AbacusTransferNGApprovalSummaryAction.Result res =
            AbacusTransferNGApprovalSummaryAction.buildResult(
                new List<AbacusTransferNG__c>{ row }
            );

        String html = res.summaryHtml;
        Assert.isTrue(
            html.contains('<li><b>100 – Alpha</b>: Net 55.55 / Gross 60.60</li>'),
            'null header rate falls back to stored CHF formulas: ' + html
        );
        Assert.isTrue(html.contains('<p><b>Total</b>: Net 55.55 / Gross 60.60</p>'));
    }

    @IsTest
    static void buildResultHandlesNullCostCenterAndNullAmounts() {
        Id inv = fakeId(Invoice__c.SObjectType);
        // No cost center, null amounts, no header rate (stored-CHF fallback path with nulls).
        AbacusTransferNG__c row = buildRow(inv, null, null, null, null, null);

        AbacusTransferNGApprovalSummaryAction.Result res =
            AbacusTransferNGApprovalSummaryAction.buildResult(
                new List<AbacusTransferNG__c>{ row }
            );

        Assert.areEqual(1, res.eligibleCount);
        Assert.areEqual(1, res.invoiceCount);
        String html = res.summaryHtml;
        Assert.isTrue(
            html.contains('<li><b>(no cost center)</b>: Net 0.00 / Gross 0.00</li>'),
            'null cost center bucket with zeroed amounts: ' + html
        );
        Assert.isTrue(html.contains('<p><b>Total</b>: Net 0.00 / Gross 0.00</p>'));
    }

    @IsTest
    static void buildResultNoCostCenterBucketSortsLast() {
        Id cc1 = fakeId(CostCenter__c.SObjectType);
        Id invA = fakeId(Invoice__c.SObjectType);
        Id invB = fakeId(Invoice__c.SObjectType);

        // No header rate set on either row: stored-CHF fallback path.
        AbacusTransferNG__c withCc = buildRow(invA, 100, 100, cc1, '100', 'Alpha');
        AbacusTransferNG__c noCc = buildRow(invB, 50, 50, null, null, null);

        AbacusTransferNGApprovalSummaryAction.Result res =
            AbacusTransferNGApprovalSummaryAction.buildResult(
                new List<AbacusTransferNG__c>{ noCc, withCc }
            );

        String html = res.summaryHtml;
        Assert.isTrue(html.indexOf('100 – Alpha') < html.indexOf('(no cost center)'),
            '(no cost center) bucket must come last: ' + html);
    }

    @IsTest
    static void buildResultWithoutInvoicesYieldsNullHtml() {
        // Rows that carry no Invoice__c at all.
        AbacusTransferNG__c r1 = buildRow(null, null, null, null, null, null);
        AbacusTransferNG__c r2 = buildRow(null, null, null, null, null, null);

        AbacusTransferNGApprovalSummaryAction.Result res =
            AbacusTransferNGApprovalSummaryAction.buildResult(
                new List<AbacusTransferNG__c>{ r1, r2 }
            );

        Assert.areEqual(2, res.eligibleCount);
        Assert.areEqual(2, res.eligibleIds.size());
        Assert.areEqual(0, res.invoiceCount);
        Assert.areEqual(null, res.summaryHtml, 'no invoices => summaryHtml is null');
    }

    @IsTest
    static void buildResultEmptyRowsIsEmptySummary() {
        AbacusTransferNGApprovalSummaryAction.Result res =
            AbacusTransferNGApprovalSummaryAction.buildResult(
                new List<AbacusTransferNG__c>()
            );
        Assert.areEqual(0, res.eligibleCount);
        Assert.areEqual(0, res.eligibleIds.size());
        Assert.areEqual(0, res.invoiceCount);
        Assert.areEqual(null, res.summaryHtml);
    }

    // ---------------------------------------------------------------------------------------
    // formatCHF unit test
    // ---------------------------------------------------------------------------------------

    @IsTest
    static void formatCHFProducesSwissFormat() {
        Assert.areEqual('1\'234\'567.50',
            AbacusTransferNGApprovalSummaryAction.formatCHF(1234567.5),
            'apostrophe thousands separators, two decimals');
        Assert.areEqual('0.00',
            AbacusTransferNGApprovalSummaryAction.formatCHF(null),
            'null => 0.00');
        Assert.areEqual('-2\'500.00',
            AbacusTransferNGApprovalSummaryAction.formatCHF(-2500),
            'leading minus for negatives');
        Assert.areEqual('1\'000.00',
            AbacusTransferNGApprovalSummaryAction.formatCHF(999.999),
            'HALF_UP rounding into next thousand');
        Assert.areEqual('0.00',
            AbacusTransferNGApprovalSummaryAction.formatCHF(0),
            'zero');
        Assert.areEqual('42.00',
            AbacusTransferNGApprovalSummaryAction.formatCHF(42),
            'sub-thousand value keeps two decimals');
    }

    // ---------------------------------------------------------------------------------------
    // summarize() real-record integration test: status/direction filtering + a real invoice.
    // ---------------------------------------------------------------------------------------

    @IsTest
    static void summarizeFiltersByStatusAndDirection() {
        // Real data graph so we can attach a real Invoice__c to the eligible row.
        TestFactory.makeData();
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];
        CostCenter__c costCenter = [SELECT Id FROM CostCenter__c LIMIT 1];
        Invoice__c inv = TestFactory.createInvoice(acc.Id, proj.Id, costCenter.Id);
        insert inv;

        // (a) outbound + PendingApproval + a real invoice => eligible.
        AbacusTransferNG__c eligible =
            AbacusTransferNGTestFactory.buildOutboundPending('Invoice Export');
        eligible.Status__c = 'PendingApproval';
        eligible.Invoice__c = inv.Id;
        // (b) outbound but already Sent => not eligible.
        AbacusTransferNG__c sent =
            AbacusTransferNGTestFactory.buildOutboundPending('Invoice Export');
        sent.Status__c = 'Sent';
        // (c) inbound => never eligible.
        AbacusTransferNG__c inbound =
            AbacusTransferNGTestFactory.buildInboundSent('Currency Import');
        insert new List<AbacusTransferNG__c>{ eligible, sent, inbound };

        AbacusTransferNGApprovalSummaryAction.Request req =
            new AbacusTransferNGApprovalSummaryAction.Request();
        req.abacusTransferNGIds = new List<Id>{ eligible.Id, sent.Id, inbound.Id };

        Test.startTest();
        List<AbacusTransferNGApprovalSummaryAction.Result> out =
            AbacusTransferNGApprovalSummaryAction.summarize(
                new List<AbacusTransferNGApprovalSummaryAction.Request>{ req }
            );
        Test.stopTest();

        Assert.areEqual(1, out.size(), 'one result per request');
        AbacusTransferNGApprovalSummaryAction.Result res = out[0];
        Assert.areEqual(1, res.eligibleCount, 'only the outbound PendingApproval row is eligible');
        Assert.areEqual(new List<Id>{ eligible.Id }, res.eligibleIds);
        Assert.areEqual(1, res.invoiceCount, 'the eligible row carries one real invoice');
        Assert.isNotNull(res.summaryHtml, 'invoice present => summary rendered');
        // A freshly inserted invoice via TestFactory has no CurrencyRateToCHF__c, so chfAmount()
        // falls back to the stored CHF formulas, which are also unset on a bare invoice with no
        // positions => both sums render as 0.00.
        Assert.isTrue(res.summaryHtml.contains('Net 0.00 / Gross 0.00'),
            'zeroed amounts on a bare invoice: ' + res.summaryHtml);
    }

    @IsTest
    static void summarizeEmptyRequestListReturnsEmpty() {
        Test.startTest();
        List<AbacusTransferNGApprovalSummaryAction.Result> out =
            AbacusTransferNGApprovalSummaryAction.summarize(
                new List<AbacusTransferNGApprovalSummaryAction.Request>()
            );
        Test.stopTest();
        Assert.areEqual(0, out.size());
    }

    @IsTest
    static void summarizeNullIdListYieldsEmptyResult() {
        AbacusTransferNGApprovalSummaryAction.Request req =
            new AbacusTransferNGApprovalSummaryAction.Request();
        req.abacusTransferNGIds = null;

        Test.startTest();
        List<AbacusTransferNGApprovalSummaryAction.Result> out =
            AbacusTransferNGApprovalSummaryAction.summarize(
                new List<AbacusTransferNGApprovalSummaryAction.Request>{ req }
            );
        Test.stopTest();

        Assert.areEqual(1, out.size());
        Assert.areEqual(0, out[0].eligibleCount);
        Assert.areEqual(0, out[0].eligibleIds.size());
        Assert.areEqual(0, out[0].invoiceCount);
        Assert.areEqual(null, out[0].summaryHtml);
    }
}
