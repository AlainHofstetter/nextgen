@IsTest
private class AbacusTransferNGCustomerGateTest {
  // The org's broken ProjectOwnerUpdateWithResponsible flow makes Project__c inserts
  // impossible in tests, and Invoice__c is master-detail to Project__c — so the gate
  // verdict logic is unit-tested through evaluateResolved with in-memory records
  // (same approach as AbacusTransferNGApprovalSummaryTest). Account.AbacusAccountNr__c
  // is a formula, hence the JSON.deserialize construction for accounts.

  private static Integer idCounter = 0;

  private static Id fakeId(Schema.SObjectType sot) {
    idCounter++;
    String prefix = sot.getDescribe().getKeyPrefix();
    String suffix = String.valueOf(idCounter);
    return Id.valueOf(prefix + '0'.repeat(12 - suffix.length()) + suffix);
  }

  private static Account buildAccount(Id accId, String name, String abacusNr) {
    Map<String, Object> acc = new Map<String, Object>{
      'Id' => accId,
      'Name' => name,
      'AbacusAccountNr__c' => abacusNr
    };
    return (Account) JSON.deserialize(JSON.serialize(acc), Account.class);
  }

  private static AbacusTransferNG__c invoiceExportRow(Id invoiceId) {
    return new AbacusTransferNG__c(
      InterfaceType__c = 'Invoice Export',
      Direction__c = 'Outbound',
      Status__c = 'PendingApproval',
      Invoice__c = invoiceId
    );
  }

  private static AbacusTransferNG__c projectExportRow(Id projectId) {
    return new AbacusTransferNG__c(
      InterfaceType__c = 'Project Export',
      Direction__c = 'Outbound',
      Status__c = 'Pending',
      Project__c = projectId
    );
  }

  private static List<String> run(
    List<AbacusTransferNG__c> rows,
    Map<Id, Invoice__c> invoicesById,
    Map<Id, Project__c> projectsById,
    Map<Id, Account> accountsById,
    Set<Id> sentDebtorAccounts
  ) {
    return AbacusTransferNGCustomerGate.evaluateResolved(
      rows,
      invoicesById,
      projectsById,
      accountsById,
      sentDebtorAccounts
    );
  }

  @IsTest
  static void invoicePassesWithLegacyNumber() {
    Id accId = fakeId(Account.SObjectType);
    Id invId = fakeId(Invoice__c.SObjectType);
    List<String> reasons = run(
      new List<AbacusTransferNG__c>{ invoiceExportRow(invId) },
      new Map<Id, Invoice__c>{
        invId => new Invoice__c(Id = invId, InvoiceReceiver__c = accId)
      },
      new Map<Id, Project__c>(),
      new Map<Id, Account>{
        accId => buildAccount(accId, 'Legacy Customer', '12345')
      },
      new Set<Id>()
    );
    System.assertEquals(1, reasons.size());
    System.assertEquals(
      null,
      reasons[0],
      'legacy Abacus number counts as existing customer'
    );
  }

  @IsTest
  static void invoicePassesWithSentDebtorRow() {
    Id accId = fakeId(Account.SObjectType);
    Id invId = fakeId(Invoice__c.SObjectType);
    List<String> reasons = run(
      new List<AbacusTransferNG__c>{ invoiceExportRow(invId) },
      new Map<Id, Invoice__c>{
        invId => new Invoice__c(Id = invId, InvoiceReceiver__c = accId)
      },
      new Map<Id, Project__c>(),
      new Map<Id, Account>{ accId => buildAccount(accId, 'NG Customer', null) },
      new Set<Id>{ accId }
    );
    System.assertEquals(
      null,
      reasons[0],
      'a Sent debtor upsert counts as existing customer'
    );
  }

  @IsTest
  static void invoiceBlockedWhenCustomerMissingInAbacus() {
    Id accId = fakeId(Account.SObjectType);
    Id invId = fakeId(Invoice__c.SObjectType);
    // The Sent-debtor set is empty: a debtor row in any non-Sent status (PendingApproval,
    // Failed, ...) never makes it into the set the gate receives, so this also covers
    // "an unsent debtor row must not count".
    List<String> reasons = run(
      new List<AbacusTransferNG__c>{ invoiceExportRow(invId) },
      new Map<Id, Invoice__c>{
        invId => new Invoice__c(Id = invId, InvoiceReceiver__c = accId)
      },
      new Map<Id, Project__c>(),
      new Map<Id, Account>{
        accId => buildAccount(accId, 'Fresh Customer', '')
      },
      new Set<Id>()
    );
    System.assertNotEquals(null, reasons[0]);
    System.assert(
      reasons[0].contains('Fresh Customer'),
      'reason names the customer: ' + reasons[0]
    );
    System.assert(reasons[0].contains('does not exist in Abacus'), reasons[0]);
  }

  @IsTest
  static void invoiceBlockedOnMissingInvoiceOrReceiver() {
    Id invId = fakeId(Invoice__c.SObjectType);
    List<String> reasons = run(
      new List<AbacusTransferNG__c>{
        invoiceExportRow(null),
        invoiceExportRow(invId)
      },
      new Map<Id, Invoice__c>{
        invId => new Invoice__c(Id = invId, InvoiceReceiver__c = null)
      },
      new Map<Id, Project__c>(),
      new Map<Id, Account>(),
      new Set<Id>()
    );
    System.assert(reasons[0].contains('no Invoice linked'), reasons[0]);
    System.assert(reasons[1].contains('no Invoice Receiver'), reasons[1]);
  }

  @IsTest
  static void projectMatrix() {
    Id legacyAcc = fakeId(Account.SObjectType);
    Id syncedAcc = fakeId(Account.SObjectType);
    Id missingAcc = fakeId(Account.SObjectType);
    Id p1 = fakeId(Project__c.SObjectType);
    Id p2 = fakeId(Project__c.SObjectType);
    Id p3 = fakeId(Project__c.SObjectType);
    Id p4 = fakeId(Project__c.SObjectType);

    List<String> reasons = run(
      new List<AbacusTransferNG__c>{
        projectExportRow(p1), // legacy number -> pass
        projectExportRow(p2), // sent debtor row -> pass
        projectExportRow(p3), // neither -> blocked
        projectExportRow(p4), // no contract partner -> blocked
        projectExportRow(null) // no project -> blocked
      },
      new Map<Id, Invoice__c>(),
      new Map<Id, Project__c>{
        p1 => new Project__c(Id = p1, ContractPartner__c = legacyAcc),
        p2 => new Project__c(Id = p2, ContractPartner__c = syncedAcc),
        p3 => new Project__c(Id = p3, ContractPartner__c = missingAcc),
        p4 => new Project__c(Id = p4, ContractPartner__c = null)
      },
      new Map<Id, Account>{
        legacyAcc => buildAccount(legacyAcc, 'Legacy Client', '98765'),
        syncedAcc => buildAccount(syncedAcc, 'Synced Client', null),
        missingAcc => buildAccount(missingAcc, 'Missing Client', null)
      },
      new Set<Id>{ syncedAcc }
    );

    System.assertEquals(null, reasons[0]);
    System.assertEquals(null, reasons[1]);
    System.assert(reasons[2].contains('Missing Client'), reasons[2]);
    System.assert(reasons[3].contains('no Contract Partner'), reasons[3]);
    System.assert(reasons[4].contains('no Project linked'), reasons[4]);
  }

  @IsTest
  static void exemptTypesAndInboundRowsPass() {
    List<AbacusTransferNG__c> rows = new List<AbacusTransferNG__c>{
      new AbacusTransferNG__c(
        InterfaceType__c = 'Cancellation Export',
        Direction__c = 'Outbound',
        Status__c = 'PendingApproval'
      ),
      new AbacusTransferNG__c(
        InterfaceType__c = 'Staff Hour Export',
        Direction__c = 'Outbound',
        Status__c = 'Pending'
      ),
      new AbacusTransferNG__c(
        InterfaceType__c = 'Account Debtor Upsert',
        Direction__c = 'Outbound',
        Status__c = 'PendingApproval'
      ),
      new AbacusTransferNG__c(
        InterfaceType__c = 'Account Supplier Upsert',
        Direction__c = 'Outbound',
        Status__c = 'PendingApproval'
      ),
      new AbacusTransferNG__c(
        InterfaceType__c = 'Invoice Export',
        Direction__c = 'Inbound',
        Status__c = 'Sent'
      )
    };
    List<String> reasons = run(
      rows,
      new Map<Id, Invoice__c>(),
      new Map<Id, Project__c>(),
      new Map<Id, Account>(),
      new Set<Id>()
    );
    for (Integer i = 0; i < reasons.size(); i++) {
      System.assertEquals(
        null,
        reasons[i],
        'row ' + i + ' must be exempt from the customer gate'
      );
    }
  }

  @IsTest
  static void mixedListKeepsPositionalAlignment() {
    Id accId = fakeId(Account.SObjectType);
    Id invId = fakeId(Invoice__c.SObjectType);
    List<String> reasons = run(
      new List<AbacusTransferNG__c>{
        new AbacusTransferNG__c(
          InterfaceType__c = 'Staff Hour Export',
          Direction__c = 'Outbound',
          Status__c = 'Pending'
        ),
        invoiceExportRow(null),
        invoiceExportRow(invId)
      },
      new Map<Id, Invoice__c>{
        invId => new Invoice__c(Id = invId, InvoiceReceiver__c = accId)
      },
      new Map<Id, Project__c>(),
      new Map<Id, Account>{
        accId => buildAccount(accId, 'Aligned Customer', '111')
      },
      new Set<Id>()
    );
    System.assertEquals(3, reasons.size());
    System.assertEquals(null, reasons[0]);
    System.assertNotEquals(null, reasons[1]);
    System.assertEquals(null, reasons[2]);
  }

  // Integration through evaluate()'s query path. Only Account DML is possible in this
  // org's tests, so this covers the no-lookup verdicts and the query short-circuits;
  // the account/debtor-row resolution itself is covered by the unit tests above and by
  // AbacusTransferNGTriggerHandlerTest / AbacusTransferNGReplayActionTest end to end.
  @IsTest
  static void evaluateQueryPathHandlesRowsWithoutLookups() {
    Test.startTest();
    List<String> reasons = AbacusTransferNGCustomerGate.evaluate(
      new List<AbacusTransferNG__c>{
        invoiceExportRow(null),
        projectExportRow(null),
        new AbacusTransferNG__c(
          InterfaceType__c = 'Cancellation Export',
          Direction__c = 'Outbound',
          Status__c = 'PendingApproval'
        )
      }
    );
    Test.stopTest();
    System.assert(reasons[0].contains('no Invoice linked'), reasons[0]);
    System.assert(reasons[1].contains('no Project linked'), reasons[1]);
    System.assertEquals(null, reasons[2]);
  }
}
