public with sharing class AbacusTransferNGReplayAction {

    @InvocableMethod(label='Replay Abacus Transfer NG' description='Resets the given AbacusTransferNG__c rows to Pending, stamps ApprovedBy/ApprovedAt, and publishes the queue Platform Event. Accepts a single Id, a collection, or both.')
    public static List<Result> replay(List<Request> requests) {
        Set<Id> ids = new Set<Id>();
        for (Request r : requests) {
            if (r.abacusTransferNGId != null) ids.add(r.abacusTransferNGId);
            if (r.abacusTransferNGIds != null) ids.addAll(r.abacusTransferNGIds);
        }
        if (ids.isEmpty()) return new List<Result>();

        List<AbacusTransferNG__c> rows = [
            SELECT Id, Name, InterfaceType__c, Status__c
            FROM AbacusTransferNG__c WHERE Id IN :ids
        ];

        Id approverId = UserInfo.getUserId();
        Datetime approvedAt = System.now();
        for (AbacusTransferNG__c row : rows) {
            row.Status__c = 'Pending';
            row.LastError__c = null;
            row.LastHttpStatus__c = null;
            row.ApprovedBy__c = approverId;
            row.ApprovedAt__c = approvedAt;
        }
        update rows;

        List<AbacusTransferNGQueued__e> events = new List<AbacusTransferNGQueued__e>();
        for (AbacusTransferNG__c row : rows) {
            events.add(new AbacusTransferNGQueued__e(
                AbacusTransferNGId__c = row.Id,
                InterfaceType__c = row.InterfaceType__c,
                IdempotencyKey__c = row.Name
            ));
        }
        EventBus.publish(events);

        List<Result> results = new List<Result>();
        for (AbacusTransferNG__c row : rows) {
            Result r = new Result();
            r.abacusTransferNGId = row.Id;
            r.status = row.Status__c;
            results.add(r);
        }
        return results;
    }

    public class Request {
        @InvocableVariable(label='Single record Id')
        public Id abacusTransferNGId;
        @InvocableVariable(label='Multiple record Ids')
        public List<Id> abacusTransferNGIds;
    }

    public class Result {
        @InvocableVariable
        public Id abacusTransferNGId;
        @InvocableVariable
        public String status;
    }
}
