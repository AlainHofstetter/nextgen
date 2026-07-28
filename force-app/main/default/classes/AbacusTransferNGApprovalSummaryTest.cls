@IsTest
private class AbacusTransferNGApprovalSummaryTest {
  // ---------------------------------------------------------------------------------------
  // In-memory helpers: formula fields (InvoiceTotalAmount*CHF__c) and nested relationship
  // objects (Invoice__r / BillingViaCompany__r) are not directly assignable in Apex, so we
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
  // BillingViaCompany__r (legal code + name). Kept as the original overload so existing call
  // sites that only care about the stored-CHF fallback path keep compiling unchanged; it
  // delegates to the full overload with null document amounts/rate, which is the null-rate
  // fallback behavior.
  private static AbacusTransferNG__c buildRow(
    Id invoiceId,
    Decimal netChf,
    Decimal grossChf,
    Id companyId,
    Decimal legalCode,
    String companyName
  ) {
    return buildRow(
      invoiceId,
      null,
      null,
      null,
      netChf,
      grossChf,
      companyId,
      legalCode,
      companyName
    );
  }

  // Full overload: also sets the document-currency totals and the header CurrencyRateToCHF__c
  // used by chfAmount() to derive CHF net/gross, alongside the stored CHF formula values that
  // now only serve as the fallback when no header rate is present.
  private static AbacusTransferNG__c buildRow(
    Id invoiceId,
    Decimal net,
    Decimal gross,
    Decimal rate,
    Decimal netChf,
    Decimal grossChf,
    Id companyId,
    Decimal legalCode,
    String companyName
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
      if (companyId != null) {
        Map<String, Object> company = new Map<String, Object>();
        company.put('Id', companyId);
        company.put('LegalCode__c', legalCode);
        company.put('Name', companyName);
        inv.put('BillingViaCompany__c', companyId);
        inv.put('BillingViaCompany__r', company);
      }
      row.put('Invoice__c', invoiceId);
      row.put('Invoice__r', inv);
    }

    return (AbacusTransferNG__c) JSON.deserialize(
      JSON.serialize(row),
      AbacusTransferNG__c.class
    );
  }

  // ---------------------------------------------------------------------------------------
  // buildResult unit tests
  // ---------------------------------------------------------------------------------------

  @IsTest
  static void buildResultGroupsAndDedupesInvoices() {
    Id co1 = fakeId(Account.SObjectType);
    Id co2 = fakeId(Account.SObjectType);
    Id invA = fakeId(Invoice__c.SObjectType);
    Id invB = fakeId(Invoice__c.SObjectType);

    // Two rows share invoice A (must count once); a third row references invoice B.
    // No header rate is set, so these exercise the stored-CHF fallback path (see
    // chfAmount()); the values below are set directly on InvoiceTotalAmount*CHF__c.
    AbacusTransferNG__c r1 = buildRow(invA, 12500, 13750, co1, 100, 'Alpha');
    AbacusTransferNG__c r2 = buildRow(invA, 12500, 13750, co1, 100, 'Alpha');
    AbacusTransferNG__c r3 = buildRow(invB, 500, 550, co2, 200, 'Beta');
    List<AbacusTransferNG__c> rows = new List<AbacusTransferNG__c>{
      r1,
      r2,
      r3
    };

    AbacusTransferNGApprovalSummaryAction.Result res = AbacusTransferNGApprovalSummaryAction.buildResult(
      rows
    );

    Assert.areEqual(3, res.eligibleCount, 'all three rows are eligible');
    Assert.areEqual(3, res.eligibleIds.size());
    Assert.areEqual(r1.Id, res.eligibleIds[0], 'eligibleIds keep row order');
    Assert.areEqual(r3.Id, res.eligibleIds[2]);
    Assert.areEqual(
      2,
      res.invoiceCount,
      'invoice A counted once despite two rows'
    );

    String html = res.summaryHtml;
    Assert.isNotNull(html);
    Assert.isTrue(
      html.contains('Invoice amounts by legal entity (CHF)'),
      'headline names legal entity: ' + html
    );
    Assert.isTrue(
      html.contains('2 invoice(s):'),
      'header shows distinct invoice count'
    );
    Assert.isTrue(
      html.contains(
        '<li><b>100 – Alpha</b>: Net 12\'500.00 / Gross 13\'750.00</li>'
      ),
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
    // Alpha (100) sorts before Beta (200).
    Assert.isTrue(
      html.indexOf('100 – Alpha') < html.indexOf('200 – Beta'),
      'groups sorted numerically by legal code'
    );
  }

  @IsTest
  static void buildResultConvertsUsingHeaderRateWhenPresent() {
    Id co1 = fakeId(Account.SObjectType);
    Id inv = fakeId(Invoice__c.SObjectType);

    // Document-currency totals converted via the header rate: 100 * 0.93 = 93.00 (exact),
    // 107.7 * 0.93 = 100.161 -> HALF_UP to 100.16. Stored CHF formulas are left null to
    // prove the conversion path (not the fallback) is what produced the result.
    AbacusTransferNG__c row = buildRow(
      inv,
      100,
      107.7,
      0.93,
      null,
      null,
      co1,
      100,
      'Alpha'
    );

    AbacusTransferNGApprovalSummaryAction.Result res = AbacusTransferNGApprovalSummaryAction.buildResult(
      new List<AbacusTransferNG__c>{ row }
    );

    String html = res.summaryHtml;
    Assert.isTrue(
      html.contains('<li><b>100 – Alpha</b>: Net 93.00 / Gross 100.16</li>'),
      'header-rate conversion with HALF_UP rounding: ' + html
    );
    Assert.isTrue(
      html.contains('<p><b>Total</b>: Net 93.00 / Gross 100.16</p>')
    );
  }

  @IsTest
  static void buildResultFallsBackToStoredChfWhenRateIsNull() {
    Id co1 = fakeId(Account.SObjectType);
    Id inv = fakeId(Invoice__c.SObjectType);

    // Document amounts are present but there is no header rate at all, so chfAmount()
    // must fall back to the stored (org-canonical) CHF formula values instead of
    // multiplying by a missing rate.
    AbacusTransferNG__c row = buildRow(
      inv,
      100,
      107.7,
      null,
      55.55,
      60.60,
      co1,
      100,
      'Alpha'
    );

    AbacusTransferNGApprovalSummaryAction.Result res = AbacusTransferNGApprovalSummaryAction.buildResult(
      new List<AbacusTransferNG__c>{ row }
    );

    String html = res.summaryHtml;
    Assert.isTrue(
      html.contains('<li><b>100 – Alpha</b>: Net 55.55 / Gross 60.60</li>'),
      'null header rate falls back to stored CHF formulas: ' + html
    );
    Assert.isTrue(
      html.contains('<p><b>Total</b>: Net 55.55 / Gross 60.60</p>')
    );
  }

  @IsTest
  static void buildResultHandlesNullLegalEntityAndNullAmounts() {
    Id inv = fakeId(Invoice__c.SObjectType);
    // No legal entity, null amounts, no header rate (stored-CHF fallback path with nulls).
    AbacusTransferNG__c row = buildRow(inv, null, null, null, null, null);

    AbacusTransferNGApprovalSummaryAction.Result res = AbacusTransferNGApprovalSummaryAction.buildResult(
      new List<AbacusTransferNG__c>{ row }
    );

    Assert.areEqual(1, res.eligibleCount);
    Assert.areEqual(1, res.invoiceCount);
    String html = res.summaryHtml;
    Assert.isTrue(
      html.contains('<li><b>(no legal entity)</b>: Net 0.00 / Gross 0.00</li>'),
      'null legal entity bucket with zeroed amounts: ' + html
    );
    Assert.isTrue(html.contains('<p><b>Total</b>: Net 0.00 / Gross 0.00</p>'));
  }

  @IsTest
  static void buildResultNoLegalEntityBucketSortsLast() {
    Id co1 = fakeId(Account.SObjectType);
    Id coNoCode = fakeId(Account.SObjectType);
    Id invA = fakeId(Invoice__c.SObjectType);
    Id invB = fakeId(Invoice__c.SObjectType);
    Id invC = fakeId(Invoice__c.SObjectType);

    // No header rate set on any row: stored-CHF fallback path. Two distinct no-entity cases
    // must both land in the single "(no legal entity)" bucket: a wholly missing company, and
    // a company that IS set but has a null LegalCode__c.
    AbacusTransferNG__c withEntity = buildRow(
      invA,
      100,
      100,
      co1,
      100,
      'Alpha'
    );
    AbacusTransferNG__c noCompany = buildRow(invB, 50, 50, null, null, null);
    AbacusTransferNG__c companyNoCode = buildRow(
      invC,
      25,
      25,
      coNoCode,
      null,
      'Codeless AG'
    );

    AbacusTransferNGApprovalSummaryAction.Result res = AbacusTransferNGApprovalSummaryAction.buildResult(
      new List<AbacusTransferNG__c>{ noCompany, withEntity, companyNoCode }
    );

    String html = res.summaryHtml;
    Assert.isTrue(
      html.indexOf('100 – Alpha') < html.indexOf('(no legal entity)'),
      '(no legal entity) bucket must come last: ' + html
    );
    // Both no-entity rows collapse into one bucket, appearing exactly once.
    Assert.areEqual(
      html.indexOf('(no legal entity)'),
      html.lastIndexOf('(no legal entity)'),
      '(no legal entity) bucket appears exactly once: ' + html
    );
  }

  @IsTest
  static void buildResultSortsGroupsNumericallyByLegalCode() {
    Id coA = fakeId(Account.SObjectType);
    Id coB = fakeId(Account.SObjectType);
    Id coC = fakeId(Account.SObjectType);
    Id invA = fakeId(Invoice__c.SObjectType);
    Id invB = fakeId(Invoice__c.SObjectType);
    Id invC = fakeId(Invoice__c.SObjectType);

    // Codes 100, 10, 25 with distinct names, passed in shuffled order. A plain alphabetical
    // sort of the labels would give "10", "100", "25"; the zero-padded numeric sort key must
    // instead order them 10 < 25 < 100.
    AbacusTransferNG__c r100 = buildRow(
      invA,
      100,
      100,
      coA,
      100,
      'Fabian Hotz Holding'
    );
    AbacusTransferNG__c r10 = buildRow(
      invB,
      100,
      100,
      coB,
      10,
      'Brand Leadership'
    );
    AbacusTransferNG__c r25 = buildRow(invC, 100, 100, coC, 25, 'gateB AG');

    AbacusTransferNGApprovalSummaryAction.Result res = AbacusTransferNGApprovalSummaryAction.buildResult(
      new List<AbacusTransferNG__c>{ r100, r10, r25 }
    );

    String html = res.summaryHtml;
    Assert.isTrue(
      html.indexOf('10 – Brand Leadership') < html.indexOf('25 – gateB AG') &&
        html.indexOf('25 – gateB AG') <
        html.indexOf('100 – Fabian Hotz Holding'),
      'groups sorted numerically (10 < 25 < 100), not alphabetically (which gives 10, 100, 25): ' +
      html
    );
  }

  @IsTest
  static void buildResultWithoutInvoicesYieldsNullHtml() {
    // Rows that carry no Invoice__c at all.
    AbacusTransferNG__c r1 = buildRow(null, null, null, null, null, null);
    AbacusTransferNG__c r2 = buildRow(null, null, null, null, null, null);

    AbacusTransferNGApprovalSummaryAction.Result res = AbacusTransferNGApprovalSummaryAction.buildResult(
      new List<AbacusTransferNG__c>{ r1, r2 }
    );

    Assert.areEqual(2, res.eligibleCount);
    Assert.areEqual(2, res.eligibleIds.size());
    Assert.areEqual(0, res.invoiceCount);
    Assert.areEqual(
      null,
      res.summaryHtml,
      'no invoices => summaryHtml is null'
    );
  }

  @IsTest
  static void buildResultEmptyRowsIsEmptySummary() {
    AbacusTransferNGApprovalSummaryAction.Result res = AbacusTransferNGApprovalSummaryAction.buildResult(
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
    Assert.areEqual(
      '1\'234\'567.50',
      AbacusTransferNGApprovalSummaryAction.formatCHF(1234567.5),
      'apostrophe thousands separators, two decimals'
    );
    Assert.areEqual(
      '0.00',
      AbacusTransferNGApprovalSummaryAction.formatCHF(null),
      'null => 0.00'
    );
    Assert.areEqual(
      '-2\'500.00',
      AbacusTransferNGApprovalSummaryAction.formatCHF(-2500),
      'leading minus for negatives'
    );
    Assert.areEqual(
      '1\'000.00',
      AbacusTransferNGApprovalSummaryAction.formatCHF(999.999),
      'HALF_UP rounding into next thousand'
    );
    Assert.areEqual(
      '0.00',
      AbacusTransferNGApprovalSummaryAction.formatCHF(0),
      'zero'
    );
    Assert.areEqual(
      '42.00',
      AbacusTransferNGApprovalSummaryAction.formatCHF(42),
      'sub-thousand value keeps two decimals'
    );
  }

  // ---------------------------------------------------------------------------------------
  // summarize() real-record integration test: status/direction filtering on invoice-less rows.
  // ---------------------------------------------------------------------------------------

  @IsTest
  static void summarizeFiltersByStatusAndDirection() {
    // No invoice is attached here on purpose: a real Invoice__c would need
    // TestFactory.makeData(), which currently dies inserting a Project__c in the broken
    // ProjectOwnerUpdateWithResponsible flow, and Invoice__c.ProjectName__c is master-detail
    // to Project__c so a real invoice cannot be built at all. The invoice/legal-entity
    // aggregation is instead covered exclusively by the buildResult unit tests above; this
    // test only exercises the status/direction eligibility filter on invoice-less rows.
    // To re-enable the invoice path once the flow is fixed: makeData()'s account already has
    // the InternalAccount record type satisfying the BillingViaCompany lookup filter, and
    // createInvoice already sets BillingViaCompany__c, but createAccount does NOT set
    // LegalCode__c — so the test must set acc.LegalCode__c before inserting the invoice or
    // the row lands in the (no legal entity) bucket.

    // (a) outbound + PendingApproval, no invoice => eligible.
    AbacusTransferNG__c eligible = AbacusTransferNGTestFactory.buildOutboundPending(
      'Invoice Export'
    );
    eligible.Status__c = 'PendingApproval';
    // (b) outbound but already Sent => not eligible.
    AbacusTransferNG__c sent = AbacusTransferNGTestFactory.buildOutboundPending(
      'Invoice Export'
    );
    sent.Status__c = 'Sent';
    // (c) inbound => never eligible.
    AbacusTransferNG__c inbound = AbacusTransferNGTestFactory.buildInboundSent(
      'Currency Import'
    );
    insert new List<AbacusTransferNG__c>{ eligible, sent, inbound };

    AbacusTransferNGApprovalSummaryAction.Request req = new AbacusTransferNGApprovalSummaryAction.Request();
    req.abacusTransferNGIds = new List<Id>{ eligible.Id, sent.Id, inbound.Id };

    Test.startTest();
    List<AbacusTransferNGApprovalSummaryAction.Result> out = AbacusTransferNGApprovalSummaryAction.summarize(
      new List<AbacusTransferNGApprovalSummaryAction.Request>{ req }
    );
    Test.stopTest();

    Assert.areEqual(1, out.size(), 'one result per request');
    AbacusTransferNGApprovalSummaryAction.Result res = out[0];
    Assert.areEqual(
      1,
      res.eligibleCount,
      'only the outbound PendingApproval row is eligible'
    );
    Assert.areEqual(new List<Id>{ eligible.Id }, res.eligibleIds);
    Assert.areEqual(0, res.invoiceCount, 'the eligible row carries no invoice');
    Assert.areEqual(
      null,
      res.summaryHtml,
      'no invoices => summaryHtml is null'
    );
  }

  @IsTest
  static void summarizeEmptyRequestListReturnsEmpty() {
    Test.startTest();
    List<AbacusTransferNGApprovalSummaryAction.Result> out = AbacusTransferNGApprovalSummaryAction.summarize(
      new List<AbacusTransferNGApprovalSummaryAction.Request>()
    );
    Test.stopTest();
    Assert.areEqual(0, out.size());
  }

  @IsTest
  static void summarizeNullIdListYieldsEmptyResult() {
    AbacusTransferNGApprovalSummaryAction.Request req = new AbacusTransferNGApprovalSummaryAction.Request();
    req.abacusTransferNGIds = null;

    Test.startTest();
    List<AbacusTransferNGApprovalSummaryAction.Result> out = AbacusTransferNGApprovalSummaryAction.summarize(
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
