public with sharing class AbacusNgSyncController {

  public class AccountRow {
    @AuraEnabled public Id id;
    @AuraEnabled public String name;
    @AuraEnabled public String accountNumber;
    @AuraEnabled public DateTime lastModifiedDate;
    @AuraEnabled public DateTime abacusNgSyncTimeStamp;
    @AuraEnabled public String ownerName;

    public AccountRow(Account a) {
      this.id = a.Id;
      this.name = a.Name;
      this.accountNumber = a.AccountNumber;
      this.lastModifiedDate = a.LastModifiedDate;
      this.abacusNgSyncTimeStamp = a.AbacusNgSyncTimeStamp__c;
      this.ownerName = a.Owner.Name;
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<AccountRow> getChangedAccounts() {
    List<Account> accounts = [
      SELECT Id, Name, AccountNumber, LastModifiedDate,
             AbacusNgSyncTimeStamp__c, Owner.Name
      FROM Account
      WHERE AbacusNgSyncTimeStamp__c = NULL
         OR LastModifiedDate > AbacusNgSyncTimeStamp__c
      WITH USER_MODE
      ORDER BY LastModifiedDate DESC
      LIMIT 500
    ];

    List<AccountRow> rows = new List<AccountRow>();
    for (Account a : accounts) {
      rows.add(new AccountRow(a));
    }
    return rows;
  }

  @AuraEnabled
  public static Integer markAccountsSynced(List<Id> accountIds) {
    if (accountIds == null || accountIds.isEmpty()) {
      return 0;
    }

    DateTime now = System.now();
    List<Account> toUpdate = new List<Account>();
    for (Id accId : accountIds) {
      toUpdate.add(new Account(Id = accId, AbacusNgSyncTimeStamp__c = now));
    }

    update as user toUpdate;
    System.debug(LoggingLevel.INFO,
      'AbacusNG sync stub: marked ' + toUpdate.size() + ' accounts as synced at ' + now);
    return toUpdate.size();
  }
}
