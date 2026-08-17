public with sharing class AbacusTransferNGCustomerGate {
  // Abacus rejects an invoice import whose debtor is missing and a project creation
  // whose client is missing, so these two exports require the customer to exist in
  // Abacus first. Account upserts ARE the customer sync, Staff Hour Export books on
  // the account itself, and a Cancellation Export implies the invoice (and therefore
  // its debtor) already reached Abacus — all exempt.
  @TestVisible
  private static final Set<String> GATED_INTERFACE_TYPES = new Set<String>{
    'Invoice Export',
    'Project Export'
  };

  private static final String DEBTOR_UPSERT_TYPE = 'Account Debtor Upsert';

  // Test hook: broken org flows make Invoice__c/Project__c inserts impossible in tests
  // (see AbacusTransferNGApprovalSummaryTest), so integration tests stub the verdicts
  // instead of building real source records. When non-null, evaluate() returns this
  // list verbatim — it must be parallel to the rows passed in.
  @TestVisible
  private static List<String> stubResults;

  /**
   * Returns a list parallel to `rows`: null = the row may go to Abacus, non-null = a
   * human-readable reason why it must not. Positional (not Id-keyed) so it also works
   * in before-insert triggers where rows have no Id yet.
   *
   * A customer counts as existing in Abacus when its Account has a legacy Abacus
   * number (AbacusAccountNr__c formula non-blank) OR a Sent 'Account Debtor Upsert'
   * transfer row.
   */
  public static List<String> evaluate(List<AbacusTransferNG__c> rows) {
    if (stubResults != null) {
      return stubResults;
    }

    Set<Id> invoiceIds = new Set<Id>();
    Set<Id> projectIds = new Set<Id>();
    for (AbacusTransferNG__c row : rows) {
      if (!isGated(row)) {
        continue;
      }
      if (row.InterfaceType__c == 'Invoice Export' && row.Invoice__c != null) {
        invoiceIds.add(row.Invoice__c);
      } else if (
        row.InterfaceType__c == 'Project Export' &&
        row.Project__c != null
      ) {
        projectIds.add(row.Project__c);
      }
    }

    Map<Id, Invoice__c> invoicesById = invoiceIds.isEmpty()
      ? new Map<Id, Invoice__c>()
      : new Map<Id, Invoice__c>(
          [
            SELECT Id, InvoiceReceiver__c
            FROM Invoice__c
            WHERE Id IN :invoiceIds
          ]
        );
    Map<Id, Project__c> projectsById = projectIds.isEmpty()
      ? new Map<Id, Project__c>()
      : new Map<Id, Project__c>(
          [
            SELECT Id, ContractPartner__c
            FROM Project__c
            WHERE Id IN :projectIds
          ]
        );

    Set<Id> accountIds = new Set<Id>();
    for (Invoice__c inv : invoicesById.values()) {
      if (inv.InvoiceReceiver__c != null) {
        accountIds.add(inv.InvoiceReceiver__c);
      }
    }
    for (Project__c proj : projectsById.values()) {
      if (proj.ContractPartner__c != null) {
        accountIds.add(proj.ContractPartner__c);
      }
    }

    Map<Id, Account> accountsById = accountIds.isEmpty()
      ? new Map<Id, Account>()
      : new Map<Id, Account>(
          [
            SELECT Id, Name, AbacusAccountNr__c
            FROM Account
            WHERE Id IN :accountIds
          ]
        );

    Set<Id> accountsWithSentDebtorRow = new Set<Id>();
    if (!accountIds.isEmpty()) {
      for (AbacusTransferNG__c debtorRow : [
        SELECT Account__c
        FROM AbacusTransferNG__c
        WHERE
          Account__c IN :accountIds
          AND InterfaceType__c = :DEBTOR_UPSERT_TYPE
          AND Status__c = 'Sent'
          AND Direction__c = 'Outbound'
      ]) {
        accountsWithSentDebtorRow.add(debtorRow.Account__c);
      }
    }

    return evaluateResolved(
      rows,
      invoicesById,
      projectsById,
      accountsById,
      accountsWithSentDebtorRow
    );
  }

  // Pure core, unit-testable without Invoice__c/Project__c DML.
  @TestVisible
  private static List<String> evaluateResolved(
    List<AbacusTransferNG__c> rows,
    Map<Id, Invoice__c> invoicesById,
    Map<Id, Project__c> projectsById,
    Map<Id, Account> accountsById,
    Set<Id> accountsWithSentDebtorRow
  ) {
    List<String> reasons = new List<String>();
    for (AbacusTransferNG__c row : rows) {
      reasons.add(
        blockReason(
          row,
          invoicesById,
          projectsById,
          accountsById,
          accountsWithSentDebtorRow
        )
      );
    }
    return reasons;
  }

  private static String blockReason(
    AbacusTransferNG__c row,
    Map<Id, Invoice__c> invoicesById,
    Map<Id, Project__c> projectsById,
    Map<Id, Account> accountsById,
    Set<Id> accountsWithSentDebtorRow
  ) {
    if (!isGated(row)) {
      return null;
    }

    Id accountId;
    if (row.InterfaceType__c == 'Invoice Export') {
      if (row.Invoice__c == null) {
        return 'Blocked: no Invoice linked to this transfer row.';
      }
      Invoice__c inv = invoicesById.get(row.Invoice__c);
      if (inv == null || inv.InvoiceReceiver__c == null) {
        return 'Blocked: the Invoice has no Invoice Receiver — Abacus needs an existing debtor to book the invoice against.';
      }
      accountId = inv.InvoiceReceiver__c;
    } else {
      if (row.Project__c == null) {
        return 'Blocked: no Project linked to this transfer row.';
      }
      Project__c proj = projectsById.get(row.Project__c);
      if (proj == null || proj.ContractPartner__c == null) {
        return 'Blocked: the Project has no Contract Partner — Abacus needs an existing client to create the project under.';
      }
      accountId = proj.ContractPartner__c;
    }

    Account acc = accountsById.get(accountId);
    Boolean hasLegacyNumber =
      acc != null && String.isNotBlank(acc.AbacusAccountNr__c);
    if (hasLegacyNumber || accountsWithSentDebtorRow.contains(accountId)) {
      return null;
    }
    String customerName = acc != null ? acc.Name : String.valueOf(accountId);
    return 'Blocked: customer \'' +
      customerName +
      '\' does not exist in Abacus yet. ' +
      'Approve & send its \'Account Debtor Upsert\' transfer first, then retry this row.';
  }

  private static Boolean isGated(AbacusTransferNG__c row) {
    return row.Direction__c == 'Outbound' &&
      GATED_INTERFACE_TYPES.contains(row.InterfaceType__c);
  }
}
