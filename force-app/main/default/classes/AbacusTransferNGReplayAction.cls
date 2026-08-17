public with sharing class AbacusTransferNGReplayAction {
  // Approve releases PendingApproval rows; replay re-releases Failed/DeadLettered rows.
  // Sent/InFlight/Cancelled and inbound audit rows must never be (re)published.
  private static final Set<String> RELEASABLE_STATUSES = new Set<String>{
    'PendingApproval',
    'Failed',
    'DeadLettered'
  };

  @InvocableMethod(
    label='Replay Abacus Transfer NG'
    description='Releases the given AbacusTransferNG__c rows to Mule: approves PendingApproval rows (stamping ApprovedBy/ApprovedAt), replays Failed/DeadLettered rows (keeping the original approval stamp), resets error/retry state to Pending, and publishes the queue Platform Event. Rows in any other status, and inbound rows, are skipped. Returns exactly one result per request.'
  )
  public static List<Result> replay(List<Request> requests) {
    List<Set<Id>> idsPerRequest = new List<Set<Id>>();
    Set<Id> allIds = new Set<Id>();
    for (Request r : requests) {
      Set<Id> ids = new Set<Id>();
      if (r.abacusTransferNGId != null)
        ids.add(r.abacusTransferNGId);
      if (r.abacusTransferNGIds != null)
        ids.addAll(r.abacusTransferNGIds);
      idsPerRequest.add(ids);
      allIds.addAll(ids);
    }

    Map<Id, AbacusTransferNG__c> released = new Map<Id, AbacusTransferNG__c>();
    if (!allIds.isEmpty()) {
      released.putAll(
        [
          SELECT
            Id,
            Name,
            InterfaceType__c,
            Status__c,
            Direction__c,
            Invoice__c,
            Project__c
          FROM AbacusTransferNG__c
          WHERE
            Id IN :allIds
            AND Status__c IN :RELEASABLE_STATUSES
            AND Direction__c = 'Outbound'
        ]
      );
    }

    // Rows whose customer does not exist in Abacus yet must not reach Mule — Abacus
    // would reject them. They keep their status (no approval stamp) and only get the
    // reason on LastError__c; every replay re-runs this gate.
    Map<Id, String> blockReasonById = new Map<Id, String>();
    List<AbacusTransferNG__c> blocked = new List<AbacusTransferNG__c>();
    if (!released.isEmpty()) {
      List<AbacusTransferNG__c> candidates = released.values();
      List<String> reasons = AbacusTransferNGCustomerGate.evaluate(candidates);
      for (Integer i = 0; i < candidates.size(); i++) {
        if (reasons[i] != null) {
          AbacusTransferNG__c row = candidates[i];
          row.LastError__c = reasons[i];
          blockReasonById.put(row.Id, reasons[i]);
          blocked.add(row);
          released.remove(row.Id);
        }
      }
    }

    List<AbacusTransferNG__c> toUpdate = new List<AbacusTransferNG__c>(blocked);
    if (!released.isEmpty()) {
      Id approverId = UserInfo.getUserId();
      Datetime approvedAt = System.now();
      List<AbacusTransferNGQueued__e> events = new List<AbacusTransferNGQueued__e>();
      for (AbacusTransferNG__c row : released.values()) {
        // Only first approval stamps the approver; replays keep the original audit trail.
        if (row.Status__c == 'PendingApproval') {
          row.ApprovedBy__c = approverId;
          row.ApprovedAt__c = approvedAt;
        }
        row.Status__c = 'Pending';
        row.LastError__c = null;
        row.LastHttpStatus__c = null;
        row.RetryCount__c = 0;
        events.add(
          new AbacusTransferNGQueued__e(
            AbacusTransferNGId__c = row.Id,
            InterfaceType__c = row.InterfaceType__c,
            IdempotencyKey__c = row.Name
          )
        );
      }
      toUpdate.addAll(released.values());
      update toUpdate;

      // AbacusTransferNGQueued__e publishes after commit, so throwing here rolls back
      // both the status updates and the queued events — no row is left at Pending
      // without its event on the bus.
      List<String> publishErrors = new List<String>();
      List<Database.SaveResult> publishResults = EventBus.publish(events);
      for (Integer i = 0; i < publishResults.size(); i++) {
        if (!publishResults[i].isSuccess()) {
          publishErrors.add(
            events[i].AbacusTransferNGId__c +
              ': ' +
              publishResults[i].getErrors()[0].getMessage()
          );
        }
      }
      if (!publishErrors.isEmpty()) {
        throw new ReplayException(
          'Platform event publish failed for ' +
            publishErrors.size() +
            ' row(s): ' +
            String.join(publishErrors, '; ')
        );
      }
    } else if (!toUpdate.isEmpty()) {
      // Nothing released, but blocked rows still need their LastError__c persisted.
      update toUpdate;
    }

    List<Result> results = new List<Result>();
    for (Set<Id> ids : idsPerRequest) {
      Result r = new Result();
      r.releasedCount = 0;
      r.blockedCount = 0;
      List<String> reasons = new List<String>();
      for (Id rowId : ids) {
        if (released.containsKey(rowId)) {
          r.releasedCount++;
          r.abacusTransferNGId = rowId;
        } else if (blockReasonById.containsKey(rowId)) {
          r.blockedCount++;
          String reason = blockReasonById.get(rowId);
          if (!reasons.contains(reason)) {
            reasons.add(reason);
          }
        }
      }
      r.blockedReason = reasons.isEmpty() ? null : String.join(reasons, '\n');
      r.skippedCount = ids.size() - r.releasedCount - r.blockedCount;
      r.status = r.releasedCount > 0
        ? 'Pending'
        : (r.blockedCount > 0 ? 'Blocked' : 'NoEligibleRows');
      results.add(r);
    }
    return results;
  }

  public class ReplayException extends Exception {
  }

  public class Request {
    @InvocableVariable(label='Single record Id')
    public Id abacusTransferNGId;
    @InvocableVariable(label='Multiple record Ids')
    public List<Id> abacusTransferNGIds;
  }

  public class Result {
    @InvocableVariable(label='Last released record Id')
    public Id abacusTransferNGId;
    @InvocableVariable(
      label='Status of released rows, Blocked, or NoEligibleRows'
    )
    public String status;
    @InvocableVariable(label='Number of rows released to Mule')
    public Integer releasedCount;
    @InvocableVariable(
      label='Number of rows skipped (not in a releasable status)'
    )
    public Integer skippedCount;
    @InvocableVariable(
      label='Number of rows blocked because their customer is not in Abacus'
    )
    public Integer blockedCount;
    @InvocableVariable(
      label='Why rows were blocked (distinct reasons, one per line)'
    )
    public String blockedReason;
  }
}
