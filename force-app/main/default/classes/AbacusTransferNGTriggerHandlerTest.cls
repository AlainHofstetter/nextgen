@IsTest
private class AbacusTransferNGTriggerHandlerTest {
  @IsTest
  static void pendingProjectExportWithoutClientIsDemotedToFailed() {
    // No Project__c linked -> the customer gate blocks; a row inserted at Pending
    // must land as Failed with the reason, so no Platform Event reaches Mule.
    AbacusTransferNG__c row = AbacusTransferNGTestFactory.buildOutboundPending(
      'Project Export'
    );

    Test.startTest();
    insert row;
    Test.stopTest();

    AbacusTransferNG__c reloaded = [
      SELECT Status__c, LastError__c
      FROM AbacusTransferNG__c
      WHERE Id = :row.Id
    ];
    System.assertEquals('Failed', reloaded.Status__c);
    System.assert(
      reloaded.LastError__c.contains('no Project linked'),
      reloaded.LastError__c
    );
  }

  @IsTest
  static void pendingProjectExportPassingGateStaysPending() {
    AbacusTransferNGCustomerGate.stubResults = new List<String>{ null };
    AbacusTransferNG__c row = AbacusTransferNGTestFactory.buildOutboundPending(
      'Project Export'
    );

    Test.startTest();
    insert row;
    Test.stopTest();

    AbacusTransferNG__c reloaded = [
      SELECT Status__c, LastError__c
      FROM AbacusTransferNG__c
      WHERE Id = :row.Id
    ];
    System.assertEquals('Pending', reloaded.Status__c);
    System.assertEquals(null, reloaded.LastError__c);
  }

  @IsTest
  static void pendingApprovalRowsAreNotGatedOnInsert() {
    // Invoice Export at PendingApproval would be blocked (no invoice), but the
    // insert gate only handles rows going straight to Pending — approval-gated
    // rows are checked at release time by AbacusTransferNGReplayAction.
    AbacusTransferNG__c row = AbacusTransferNGTestFactory.buildOutboundPending(
      'Invoice Export'
    );
    row.Status__c = 'PendingApproval';

    Test.startTest();
    insert row;
    Test.stopTest();

    AbacusTransferNG__c reloaded = [
      SELECT Status__c, LastError__c
      FROM AbacusTransferNG__c
      WHERE Id = :row.Id
    ];
    System.assertEquals('PendingApproval', reloaded.Status__c);
    System.assertEquals(null, reloaded.LastError__c);
  }

  @IsTest
  static void exemptTypeAtPendingStaysPending() {
    AbacusTransferNG__c row = AbacusTransferNGTestFactory.buildOutboundPending(
      'Staff Hour Export'
    );

    Test.startTest();
    insert row;
    Test.stopTest();

    System.assertEquals(
      'Pending',
      [SELECT Status__c FROM AbacusTransferNG__c WHERE Id = :row.Id].Status__c
    );
  }

  @IsTest
  static void bulkInsertMixesGatedAndUntouchedRows() {
    AbacusTransferNG__c blockedProject = AbacusTransferNGTestFactory.buildOutboundPending(
      'Project Export'
    );
    AbacusTransferNG__c staffHour = AbacusTransferNGTestFactory.buildOutboundPending(
      'Staff Hour Export'
    );
    AbacusTransferNG__c pendingApproval = AbacusTransferNGTestFactory.buildOutboundPending(
      'Invoice Export'
    );
    pendingApproval.Status__c = 'PendingApproval';

    Test.startTest();
    insert new List<AbacusTransferNG__c>{
      blockedProject,
      staffHour,
      pendingApproval
    };
    Test.stopTest();

    Map<Id, AbacusTransferNG__c> reloaded = new Map<Id, AbacusTransferNG__c>(
      [
        SELECT Status__c, LastError__c
        FROM AbacusTransferNG__c
        WHERE
          Id IN :new List<Id>{
            blockedProject.Id,
            staffHour.Id,
            pendingApproval.Id
          }
      ]
    );
    System.assertEquals('Failed', reloaded.get(blockedProject.Id).Status__c);
    System.assertNotEquals(null, reloaded.get(blockedProject.Id).LastError__c);
    System.assertEquals('Pending', reloaded.get(staffHour.Id).Status__c);
    System.assertEquals(
      'PendingApproval',
      reloaded.get(pendingApproval.Id).Status__c
    );
  }
}
