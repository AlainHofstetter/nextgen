@IsTest
private class AbacusNgSyncControllerTest {

  @TestSetup
  static void setup() {
    List<Account> accounts = new List<Account>();
    for (Integer i = 0; i < 5; i++) {
      accounts.add(new Account(Name = 'AbacusNg Test Account ' + i));
    }
    insert accounts;

    accounts[0].AbacusNgSyncTimeStamp__c = System.now().addDays(1);
    update accounts[0];
  }

  @IsTest
  static void getChangedAccounts_returnsNeverSyncedAndStaleAccounts() {
    Test.startTest();
    List<AbacusNgSyncController.AccountRow> rows = AbacusNgSyncController.getChangedAccounts();
    Test.stopTest();

    System.assertEquals(4, rows.size(),
      'Should return 4 accounts (never-synced); the one synced in the future is excluded.');
    for (AbacusNgSyncController.AccountRow r : rows) {
      System.assertNotEquals(null, r.id);
      System.assertNotEquals(null, r.name);
    }
  }

  @IsTest
  static void markAccountsSynced_updatesTimestampForGivenIds() {
    List<Account> toSync = [
      SELECT Id FROM Account WHERE AbacusNgSyncTimeStamp__c = NULL LIMIT 2
    ];
    List<Id> ids = new List<Id>();
    for (Account a : toSync) ids.add(a.Id);

    Test.startTest();
    Integer count = AbacusNgSyncController.markAccountsSynced(ids);
    Test.stopTest();

    System.assertEquals(2, count);
    Integer stillUnsynced = [
      SELECT COUNT() FROM Account WHERE Id IN :ids AND AbacusNgSyncTimeStamp__c = NULL
    ];
    System.assertEquals(0, stillUnsynced, 'Both selected accounts should now have a sync timestamp.');
  }

  @IsTest
  static void markAccountsSynced_emptyListReturnsZero() {
    System.assertEquals(0, AbacusNgSyncController.markAccountsSynced(null));
    System.assertEquals(0, AbacusNgSyncController.markAccountsSynced(new List<Id>()));
  }
}
