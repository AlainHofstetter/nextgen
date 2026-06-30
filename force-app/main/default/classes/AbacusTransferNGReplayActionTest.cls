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
            SELECT Status__c, LastError__c, LastHttpStatus__c
            FROM AbacusTransferNG__c WHERE Id = :row.Id
        ];
        System.assertEquals('Pending', reloaded.Status__c);
        System.assertEquals(null, reloaded.LastError__c);
        System.assertEquals(null, reloaded.LastHttpStatus__c);
        System.assertEquals(1, out.size());
        System.assertEquals('Pending', out[0].status);
        System.assertEquals(row.Id, out[0].abacusTransferNGId);
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
