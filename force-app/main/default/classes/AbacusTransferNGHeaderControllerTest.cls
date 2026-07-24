@IsTest
private class AbacusTransferNGHeaderControllerTest {
  // ---------------------------------------------------------------------------------------
  // In-memory helpers: formula fields (InvoiceTotalAmountGrossCHF__c) and the nested
  // Invoice__r relationship are not directly assignable in Apex, so we build the rows via
  // JSON.deserialize which happily populates read-only fields.
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

  // Builds an AbacusTransferNG__c row (Id set) with an optional nested Invoice__r carrying
  // the document-currency gross, the header CurrencyRateToCHF__c and the stored gross CHF
  // formula value used by sumGrossChf().
  private static AbacusTransferNG__c buildRow(
    Id invoiceId,
    Decimal gross,
    Decimal rate,
    Decimal grossChf
  ) {
    Map<String, Object> row = new Map<String, Object>();
    row.put('Id', fakeId(AbacusTransferNG__c.SObjectType));

    if (invoiceId != null) {
      Map<String, Object> inv = new Map<String, Object>();
      inv.put('Id', invoiceId);
      inv.put('InvoiceTotalAmountGross__c', gross);
      inv.put('InvoiceTotalAmountGrossCHF__c', grossChf);
      inv.put('CurrencyRateToCHF__c', rate);
      row.put('Invoice__c', invoiceId);
      row.put('Invoice__r', inv);
    }

    return (AbacusTransferNG__c) JSON.deserialize(
      JSON.serialize(row),
      AbacusTransferNG__c.class
    );
  }

  // ---------------------------------------------------------------------------------------
  // sumGrossChf unit tests
  // ---------------------------------------------------------------------------------------

  @IsTest
  static void sumGrossChfUsesHeaderRateWhenPresent() {
    Id inv = fakeId(Invoice__c.SObjectType);
    // Header rate present: 107.7 * 0.93 = 100.161 (exact Decimal product, no rounding).
    // Stored gross CHF left null to prove the conversion path, not the fallback, was used.
    AbacusTransferNG__c row = buildRow(inv, 107.7, 0.93, null);

    Decimal total = AbacusTransferNGHeaderController.sumGrossChf(
      new List<AbacusTransferNG__c>{ row }
    );

    Assert.areEqual(100.161, total, 'gross x header rate');
  }

  @IsTest
  static void sumGrossChfFallsBackToStoredChfWhenRateIsNull() {
    Id inv = fakeId(Invoice__c.SObjectType);
    // No header rate at all, so sumGrossChf() must fall back to the stored gross CHF value.
    AbacusTransferNG__c row = buildRow(inv, 107.7, null, 60.60);

    Decimal total = AbacusTransferNGHeaderController.sumGrossChf(
      new List<AbacusTransferNG__c>{ row }
    );

    Assert.areEqual(
      60.60,
      total,
      'null header rate falls back to stored gross CHF'
    );
  }

  @IsTest
  static void sumGrossChfDedupesInvoices() {
    Id inv = fakeId(Invoice__c.SObjectType);
    // Two rows reference the SAME invoice: it must be counted (and summed) exactly once.
    AbacusTransferNG__c r1 = buildRow(inv, 107.7, 0.93, null);
    AbacusTransferNG__c r2 = buildRow(inv, 107.7, 0.93, null);

    Decimal total = AbacusTransferNGHeaderController.sumGrossChf(
      new List<AbacusTransferNG__c>{ r1, r2 }
    );

    Assert.areEqual(
      100.161,
      total,
      'same invoice across two rows counted once'
    );
  }

  @IsTest
  static void sumGrossChfTreatsNullAmountsAsZero() {
    Id invA = fakeId(Invoice__c.SObjectType);
    Id invB = fakeId(Invoice__c.SObjectType);
    // (a) header rate present but null gross => 0 * rate = 0.
    AbacusTransferNG__c withRate = buildRow(invA, null, 0.93, null);
    // (b) no rate and no stored gross CHF => 0.
    AbacusTransferNG__c allNull = buildRow(invB, null, null, null);

    Decimal total = AbacusTransferNGHeaderController.sumGrossChf(
      new List<AbacusTransferNG__c>{ withRate, allNull }
    );

    Assert.areEqual(0, total, 'null amounts contribute 0');
  }

  @IsTest
  static void sumGrossChfEmptyListIsZero() {
    Decimal total = AbacusTransferNGHeaderController.sumGrossChf(
      new List<AbacusTransferNG__c>()
    );
    Assert.areEqual(0, total, 'empty list sums to 0');
  }

  // ---------------------------------------------------------------------------------------
  // getHeaderData() integration test with real DML.
  // ---------------------------------------------------------------------------------------

  @IsTest
  static void getHeaderDataAggregatesRealRows() {
    // No invoice is created here on purpose: TestFactory.makeData() (needed for a real
    // Invoice__c) currently dies in the ProjectOwnerUpdateWithResponsible flow, and a
    // freshly inserted invoice's gross formula reads 0 anyway (deferred rollups), so the
    // invoice-linked CHF paths are covered exclusively by the sumGrossChf unit tests
    // above. Transfer rows themselves need no lookups and insert cleanly.
    AbacusTransferNG__c pending1 = AbacusTransferNGTestFactory.buildOutboundPending(
      'Invoice Export'
    );
    pending1.Status__c = 'PendingApproval';
    AbacusTransferNG__c pending2 = AbacusTransferNGTestFactory.buildOutboundPending(
      'Invoice Export'
    );
    pending2.Status__c = 'PendingApproval';
    // One plain Pending row (not counted).
    AbacusTransferNG__c pending = AbacusTransferNGTestFactory.buildOutboundPending(
      'Invoice Export'
    );
    // Two Sent rows with distinct explicit SentAt__c values; the later one is the MAX.
    Datetime earlier = Datetime.newInstance(2026, 1, 1, 8, 0, 0);
    Datetime later = Datetime.newInstance(2026, 6, 15, 14, 30, 0);
    AbacusTransferNG__c sentEarly = AbacusTransferNGTestFactory.buildOutboundPending(
      'Invoice Export'
    );
    sentEarly.Status__c = 'Sent';
    sentEarly.SentAt__c = earlier;
    AbacusTransferNG__c sentLate = AbacusTransferNGTestFactory.buildOutboundPending(
      'Invoice Export'
    );
    sentLate.Status__c = 'Sent';
    sentLate.SentAt__c = later;
    insert new List<AbacusTransferNG__c>{
      pending1,
      pending2,
      pending,
      sentEarly,
      sentLate
    };

    Test.startTest();
    AbacusTransferNGHeaderController.HeaderData data = AbacusTransferNGHeaderController.getHeaderData();
    Map<String, Integer> counts = AbacusTransferNGHeaderController.getStatusCounts();
    Test.stopTest();

    Assert.areEqual(2, data.pendingCount, 'two PendingApproval rows');
    Assert.areEqual(
      later,
      data.lastTransferAt,
      'lastTransferAt is the latest SentAt'
    );
    Assert.areEqual(
      0,
      data.totalInvoiceGrossChf,
      'no invoice-linked pending rows'
    );

    Assert.areEqual(
      2,
      counts.get('PendingApproval'),
      'two PendingApproval rows'
    );
    Assert.areEqual(1, counts.get('Pending'), 'one plain Pending row');
    Assert.areEqual(2, counts.get('Sent'), 'two Sent rows');
    Assert.isFalse(
      counts.containsKey('Failed'),
      'no Failed rows => key absent'
    );
  }

  // ---------------------------------------------------------------------------------------
  // getHeaderData() with no transfer rows: everything zero / null.
  // ---------------------------------------------------------------------------------------

  @IsTest
  static void getHeaderDataEmptyReturnsZeros() {
    // No AbacusTransferNG__c rows are created, and nothing in this test context can
    // enqueue any (the Invoice flow only fires on update to InvoiceStatus__c = Ready).
    Test.startTest();
    AbacusTransferNGHeaderController.HeaderData data = AbacusTransferNGHeaderController.getHeaderData();
    Map<String, Integer> counts = AbacusTransferNGHeaderController.getStatusCounts();
    Test.stopTest();

    Assert.areEqual(0, data.pendingCount, 'no pending rows');
    Assert.areEqual(0, data.totalInvoiceGrossChf, 'no invoices to sum');
    Assert.isNull(data.lastTransferAt, 'no Sent rows => MAX(SentAt) is null');
    Assert.isTrue(counts.isEmpty(), 'no rows => empty status-count map');
  }
}
