public with sharing class AbacusTransferNGTriggerHandler {
  /**
   * Rows inserted straight at Pending skip the approval gate in
   * AbacusTransferNGReplayAction (e.g. Project Export from RTF_Project_AbacusTransferNG),
   * so the customer gate runs here instead: blocked rows are demoted to Failed with the
   * reason on LastError__c. That keeps RTF_AbacusTransferNG_PublishPE (create-only,
   * Status = Pending) from publishing the event to Mule, and Failed is releasable via
   * the existing Approve & Push action once the customer exists in Abacus — the gate
   * re-runs there. Rows inserted at PendingApproval are left alone; they are gated at
   * release time.
   */
  public static void handleBeforeInsert(List<AbacusTransferNG__c> rows) {
    List<AbacusTransferNG__c> candidates = new List<AbacusTransferNG__c>();
    for (AbacusTransferNG__c row : rows) {
      if (row.Status__c == 'Pending') {
        candidates.add(row);
      }
    }
    if (candidates.isEmpty()) {
      return;
    }
    List<String> reasons = AbacusTransferNGCustomerGate.evaluate(candidates);
    for (Integer i = 0; i < candidates.size(); i++) {
      if (reasons[i] != null) {
        candidates[i].Status__c = 'Failed';
        candidates[i].LastError__c = reasons[i];
      }
    }
  }
}
