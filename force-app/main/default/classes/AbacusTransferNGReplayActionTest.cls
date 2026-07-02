@IsTest
private class AbacusTransferNGReplayActionTest {

    @IsTest
    static void replayResetsAndPublishes() {
        AbacusTransferNG__c row = AbacusTransferNGTestFactory.buildFailed('Invoice Export', 'previously failed');
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
            FROM AbacusTransferNG__c WHERE Id = :row.Id
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
        AbacusTransferNG__c pendingApproval = AbacusTransferNGTestFactory.buildOutboundPending('Invoice Export');
        pendingApproval.Status__c = 'PendingApproval';
        AbacusTransferNG__c failed = AbacusTransferNGTestFactory.buildFailed('Invoice Export', 'boom');
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

        Map<Id, AbacusTransferNG__c> reloaded = new Map<Id, AbacusTransferNG__c>([
            SELECT Status__c, ApprovedBy__c, ApprovedAt__c FROM AbacusTransferNG__c
            WHERE Id IN :req.abacusTransferNGIds
        ]);
        System.assertEquals('Pending', reloaded.get(pendingApproval.Id).Status__c);
        System.assertEquals(UserInfo.getUserId(), reloaded.get(pendingApproval.Id).ApprovedBy__c);
        System.assertNotEquals(null, reloaded.get(pendingApproval.Id).ApprovedAt__c);
        System.assertEquals('Pending', reloaded.get(failed.Id).Status__c);
        System.assertEquals(originalApprovedAt, reloaded.get(failed.Id).ApprovedAt__c,
            'replay must keep the original approval stamp');
    }

    @IsTest
    static void replaySkipsNonReleasableRows() {
        AbacusTransferNG__c sent = AbacusTransferNGTestFactory.buildOutboundPending('Invoice Export');
        sent.Status__c = 'Sent';
        AbacusTransferNG__c cancelled = AbacusTransferNGTestFactory.buildOutboundPending('Invoice Export');
        cancelled.Status__c = 'Cancelled';
        AbacusTransferNG__c inbound = AbacusTransferNGTestFactory.buildInboundSent('Currency Import');
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
        System.assertEquals('Sent', [SELECT Status__c FROM AbacusTransferNG__c WHERE Id = :sent.Id].Status__c);
        System.assertEquals('Cancelled', [SELECT Status__c FROM AbacusTransferNG__c WHERE Id = :cancelled.Id].Status__c);
        System.assertEquals('Failed', [SELECT Status__c FROM AbacusTransferNG__c WHERE Id = :inbound.Id].Status__c,
            'inbound rows must never be replayed');
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
