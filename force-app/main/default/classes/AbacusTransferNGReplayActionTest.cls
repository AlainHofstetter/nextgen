@IsTest
private class AbacusTransferNGReplayActionTest {
  // Release-mechanics tests use 'Cancellation Export' rows: the type is exempt from
  // the customer gate, and a real Invoice__c cannot be inserted in this org's tests
  // (master-detail to Project__c, whose insert dies in a broken flow). The gate's
  // blocked paths are covered further down and in AbacusTransferNGCustomerGateTest.

  @IsTest
  static void replayResetsAndPublishes() {
    AbacusTransferNG__c row = AbacusTransferNGTestFactory.buildFailed(
      'Cancellation Export',
      'previously failed'
    );
    insert row;

    AbacusTransferNGReplayAction.Request req = new AbacusTransferNGReplayAction.Request();
    req.abacusTransferNGId = row.Id;

    Test.startTest();
    List<AbacusTransferNGReplayAction.Result> out = AbacusTransferNGReplayAction.replay(
      new List<AbacusTransferNGReplayAction.Request>{ req }
    );
    Test.stopTest();

    AbacusTransferNG__c reloaded = [
      SELECT Status__c, LastError__c, LastHttpStatus__c, RetryCount__c
      FROM AbacusTransferNG__c
      WHERE Id = :row.Id
    ];
    System.assertEquals('Pending', reloaded.Status__c);
    System.assertEquals(null, reloaded.LastError__c);
    System.assertEquals(null, reloaded.LastHttpStatus__c);
    System.assertEquals(0, reloaded.RetryCount__c);
    System.assertEquals(1, out.size());
    System.assertEquals('Pending', out[0].status);
    System.assertEquals(row.Id, out[0].abacusTransferNGId);
    System.assertEquals(1, out[0].releasedCount);
    System.assertEquals(0, out[0].skippedCount);
  }

  @IsTest
  static void approveStampsApproverOnlyOnFirstApproval() {
    AbacusTransferNG__c pendingApproval = AbacusTransferNGTestFactory.buildOutboundPending(
      'Cancellation Export'
    );
    pendingApproval.Status__c = 'PendingApproval';
    AbacusTransferNG__c failed = AbacusTransferNGTestFactory.buildFailed(
      'Cancellation Export',
      'boom'
    );
    Datetime originalApprovedAt = Datetime.now().addDays(-3);
    failed.ApprovedBy__c = UserInfo.getUserId();
    failed.ApprovedAt__c = originalApprovedAt;
    insert new List<AbacusTransferNG__c>{ pendingApproval, failed };

    AbacusTransferNGReplayAction.Request req = new AbacusTransferNGReplayAction.Request();
    req.abacusTransferNGIds = new List<Id>{ pendingApproval.Id, failed.Id };

    Test.startTest();
    List<AbacusTransferNGReplayAction.Result> out = AbacusTransferNGReplayAction.replay(
      new List<AbacusTransferNGReplayAction.Request>{ req }
    );
    Test.stopTest();

    System.assertEquals(1, out.size(), 'one result per request');
    System.assertEquals(2, out[0].releasedCount);

    Map<Id, AbacusTransferNG__c> reloaded = new Map<Id, AbacusTransferNG__c>(
      [
        SELECT Status__c, ApprovedBy__c, ApprovedAt__c
        FROM AbacusTransferNG__c
        WHERE Id IN :req.abacusTransferNGIds
      ]
    );
    System.assertEquals('Pending', reloaded.get(pendingApproval.Id).Status__c);
    System.assertEquals(
      UserInfo.getUserId(),
      reloaded.get(pendingApproval.Id).ApprovedBy__c
    );
    System.assertNotEquals(
      null,
      reloaded.get(pendingApproval.Id).ApprovedAt__c
    );
    System.assertEquals('Pending', reloaded.get(failed.Id).Status__c);
    System.assertEquals(
      originalApprovedAt,
      reloaded.get(failed.Id).ApprovedAt__c,
      'replay must keep the original approval stamp'
    );
  }

  @IsTest
  static void replaySkipsNonReleasableRows() {
    AbacusTransferNG__c sent = AbacusTransferNGTestFactory.buildOutboundPending(
      'Invoice Export'
    );
    sent.Status__c = 'Sent';
    AbacusTransferNG__c cancelled = AbacusTransferNGTestFactory.buildOutboundPending(
      'Invoice Export'
    );
    cancelled.Status__c = 'Cancelled';
    AbacusTransferNG__c inbound = AbacusTransferNGTestFactory.buildInboundSent(
      'Currency Import'
    );
    inbound.Status__c = 'Failed';
    insert new List<AbacusTransferNG__c>{ sent, cancelled, inbound };

    AbacusTransferNGReplayAction.Request req = new AbacusTransferNGReplayAction.Request();
    req.abacusTransferNGIds = new List<Id>{ sent.Id, cancelled.Id, inbound.Id };

    Test.startTest();
    List<AbacusTransferNGReplayAction.Result> out = AbacusTransferNGReplayAction.replay(
      new List<AbacusTransferNGReplayAction.Request>{ req }
    );
    Test.stopTest();

    System.assertEquals(1, out.size());
    System.assertEquals('NoEligibleRows', out[0].status);
    System.assertEquals(0, out[0].releasedCount);
    System.assertEquals(3, out[0].skippedCount);
    System.assertEquals(
      'Sent',
      [SELECT Status__c FROM AbacusTransferNG__c WHERE Id = :sent.Id].Status__c
    );
    System.assertEquals(
      'Cancelled',
      [SELECT Status__c FROM AbacusTransferNG__c WHERE Id = :cancelled.Id]
      .Status__c
    );
    System.assertEquals(
      'Failed',
      [SELECT Status__c FROM AbacusTransferNG__c WHERE Id = :inbound.Id]
      .Status__c,
      'inbound rows must never be replayed'
    );
  }

  @IsTest
  static void blockedRowStaysUnapprovedAndReportsReason() {
    // Invoice Export with no Invoice__c linked -> customer gate blocks the release.
    AbacusTransferNG__c row = AbacusTransferNGTestFactory.buildOutboundPending(
      'Invoice Export'
    );
    row.Status__c = 'PendingApproval';
    insert row;

    AbacusTransferNGReplayAction.Request req = new AbacusTransferNGReplayAction.Request();
    req.abacusTransferNGId = row.Id;

    Test.startTest();
    List<AbacusTransferNGReplayAction.Result> out = AbacusTransferNGReplayAction.replay(
      new List<AbacusTransferNGReplayAction.Request>{ req }
    );
    Test.stopTest();

    AbacusTransferNG__c reloaded = [
      SELECT Status__c, LastError__c, ApprovedBy__c, ApprovedAt__c
      FROM AbacusTransferNG__c
      WHERE Id = :row.Id
    ];
    System.assertEquals(
      'PendingApproval',
      reloaded.Status__c,
      'blocked rows keep their status'
    );
    System.assertEquals(
      null,
      reloaded.ApprovedBy__c,
      'blocked rows must not be stamped as approved'
    );
    System.assertEquals(null, reloaded.ApprovedAt__c);
    System.assertNotEquals(null, reloaded.LastError__c);
    System.assert(
      reloaded.LastError__c.contains('no Invoice linked'),
      reloaded.LastError__c
    );

    System.assertEquals('Blocked', out[0].status);
    System.assertEquals(0, out[0].releasedCount);
    System.assertEquals(1, out[0].blockedCount);
    System.assertEquals(0, out[0].skippedCount);
    System.assert(
      out[0].blockedReason.contains('no Invoice linked'),
      out[0].blockedReason
    );
  }

  @IsTest
  static void mixedRequestReleasesEligibleAndBlocksOthers() {
    AbacusTransferNG__c releasable = AbacusTransferNGTestFactory.buildFailed(
      'Cancellation Export',
      'boom'
    );
    AbacusTransferNG__c blocked = AbacusTransferNGTestFactory.buildOutboundPending(
      'Invoice Export'
    );
    blocked.Status__c = 'PendingApproval';
    insert new List<AbacusTransferNG__c>{ releasable, blocked };

    AbacusTransferNGReplayAction.Request req = new AbacusTransferNGReplayAction.Request();
    req.abacusTransferNGIds = new List<Id>{ releasable.Id, blocked.Id };

    Test.startTest();
    List<AbacusTransferNGReplayAction.Result> out = AbacusTransferNGReplayAction.replay(
      new List<AbacusTransferNGReplayAction.Request>{ req }
    );
    Test.stopTest();

    System.assertEquals(
      'Pending',
      out[0].status,
      'partial release reports the released status'
    );
    System.assertEquals(1, out[0].releasedCount);
    System.assertEquals(1, out[0].blockedCount);
    System.assertEquals(0, out[0].skippedCount);

    System.assertEquals(
      'Pending',
      [SELECT Status__c FROM AbacusTransferNG__c WHERE Id = :releasable.Id]
      .Status__c
    );
    System.assertEquals(
      'PendingApproval',
      [SELECT Status__c FROM AbacusTransferNG__c WHERE Id = :blocked.Id]
      .Status__c
    );
  }

  @IsTest
  static void failedProjectRowReleasesOnceCustomerExists() {
    // A Project Export demoted to Failed by the insert gate is replayed after the
    // customer reached Abacus. A real Project__c cannot be inserted in tests, so the
    // gate verdict is stubbed to pass; the resolution logic itself is covered by
    // AbacusTransferNGCustomerGateTest.
    AbacusTransferNG__c row = AbacusTransferNGTestFactory.buildFailed(
      'Project Export',
      'Blocked: customer does not exist in Abacus yet.'
    );
    Datetime originalApprovedAt = Datetime.now().addDays(-1);
    row.ApprovedBy__c = UserInfo.getUserId();
    row.ApprovedAt__c = originalApprovedAt;
    insert row;

    AbacusTransferNGCustomerGate.stubResults = new List<String>{ null };
    AbacusTransferNGReplayAction.Request req = new AbacusTransferNGReplayAction.Request();
    req.abacusTransferNGId = row.Id;

    Test.startTest();
    List<AbacusTransferNGReplayAction.Result> out = AbacusTransferNGReplayAction.replay(
      new List<AbacusTransferNGReplayAction.Request>{ req }
    );
    Test.stopTest();

    AbacusTransferNG__c reloaded = [
      SELECT Status__c, LastError__c, ApprovedAt__c
      FROM AbacusTransferNG__c
      WHERE Id = :row.Id
    ];
    System.assertEquals('Pending', reloaded.Status__c);
    System.assertEquals(
      null,
      reloaded.LastError__c,
      'release clears the blocked reason'
    );
    System.assertEquals(
      originalApprovedAt,
      reloaded.ApprovedAt__c,
      'replay keeps the original approval stamp'
    );
    System.assertEquals(1, out[0].releasedCount);
    System.assertEquals(0, out[0].blockedCount);
  }

  @IsTest
  static void replayEmptyListReturnsEmpty() {
    Test.startTest();
    List<AbacusTransferNGReplayAction.Result> out = AbacusTransferNGReplayAction.replay(
      new List<AbacusTransferNGReplayAction.Request>()
    );
    Test.stopTest();
    System.assertEquals(0, out.size());
  }
}
