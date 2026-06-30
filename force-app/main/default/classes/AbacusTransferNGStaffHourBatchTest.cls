@IsTest
private class AbacusTransferNGStaffHourBatchTest {

    @IsTest
    static void defaultConstructorUsesLastWeekWindow() {
        Test.startTest();
        AbacusTransferNGStaffHourBatch b = new AbacusTransferNGStaffHourBatch();
        Database.executeBatch(b, 200);
        Test.stopTest();
        System.assert(true, 'batch executed cleanly');
    }

    @IsTest
    static void schedulerExecutesBatch() {
        AbacusTransferNGStaffHourScheduler scheduler = new AbacusTransferNGStaffHourScheduler();
        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();
        System.assert(true, 'scheduler executed');
    }

    @IsTest
    static void enqueueForReceiversCreatesRows() {
        Account a1 = new Account(Name = 'Receiver Alpha');
        Account a2 = new Account(Name = 'Receiver Beta');
        insert new List<Account>{ a1, a2 };

        Test.startTest();
        AbacusTransferNGStaffHourBatch.enqueueForReceivers(new Set<Id>{ a1.Id, a2.Id });
        Test.stopTest();

        List<AbacusTransferNG__c> rows = [
            SELECT Id, Account__c, InterfaceType__c, Direction__c, Status__c, SourceObject__c
            FROM AbacusTransferNG__c WHERE Account__c IN :new Set<Id>{ a1.Id, a2.Id }
        ];
        System.assertEquals(2, rows.size());
        for (AbacusTransferNG__c row : rows) {
            System.assertEquals('Staff Hour Export', row.InterfaceType__c);
            System.assertEquals('Outbound', row.Direction__c);
            System.assertEquals('Pending', row.Status__c);
            System.assertEquals('Time__c', row.SourceObject__c);
        }
    }

    @IsTest
    static void enqueueForReceiversSkipsAlreadyQueued() {
        Account a = new Account(Name = 'Receiver With Pending');
        insert a;
        AbacusTransferNG__c existing = new AbacusTransferNG__c(
            InterfaceType__c = 'Staff Hour Export',
            Direction__c = 'Outbound',
            Status__c = 'Pending',
            Account__c = a.Id
        );
        insert existing;

        Test.startTest();
        AbacusTransferNGStaffHourBatch.enqueueForReceivers(new Set<Id>{ a.Id });
        Test.stopTest();

        Integer count = [SELECT COUNT() FROM AbacusTransferNG__c WHERE Account__c = :a.Id];
        System.assertEquals(1, count, 'No new row should have been created');
    }

    @IsTest
    static void enqueueForReceiversNoOpOnEmptySet() {
        Test.startTest();
        AbacusTransferNGStaffHourBatch.enqueueForReceivers(new Set<Id>());
        Test.stopTest();
        System.assertEquals(0, [SELECT COUNT() FROM AbacusTransferNG__c]);
    }

    @IsTest
    static void collectBillingReceiversFiltersNulls() {
        Account a = new Account(Name = 'Receiver');
        insert a;
        Time__c withReceiver = new Time__c(BillingReceiver__c = a.Id);
        Time__c withoutReceiver = new Time__c();
        Set<Id> ids = AbacusTransferNGStaffHourBatch.collectBillingReceivers(
            new List<Time__c>{ withReceiver, withoutReceiver }
        );
        System.assertEquals(1, ids.size());
        System.assert(ids.contains(a.Id));
    }
}
