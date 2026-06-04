public class HumanResourcesTabController {

  /*
   * Load the time entries
   */
  @AuraEnabled
  public static List<Time__c> listTimeEntries(String dateFrom, String dateUntil, Id timetracker) {

    Date parsedDateFrom = Date.valueOf(dateFrom);
    Date parsedDateUntil = Date.valueOf(dateUntil);

    return [
      SELECT AbacusTimeType__c, DateFrom__c, DurationHhMmN__c, Id, Timetracker__c, TimeValidatedHumanResources__c
      FROM Time__c
      WHERE Id != null
        AND Timetracker__c = :timetracker
        AND DateFrom__c >= :parsedDateFrom
        AND DateFrom__c <= :parsedDateUntil
      LIMIT 2000
    ];

  }

  /*
   * Load the contacts for an account so we can paginate through them
   */
  @AuraEnabled
  public static List<Contact> loadContactsForAccount(String filterById) {

    String recordTypeName = 'Internal Contact';
    String baseQuery = 'SELECT Id, Name, Account.Name, AccountId FROM Contact WHERE RecordType.Name = :recordTypeName ';

    if(filterById != null){
      baseQuery += ' and AccountId = :filterById ';
    }

    baseQuery += ' ORDER BY LastName, FirstName';

    return Database.query(baseQuery);
  }

  @AuraEnabled
  public static PackageSelector.Model get(String params) {
    PackageSelector.Params parameters = (PackageSelector.Params) JSON.deserialize(params, PackageSelector.Params.class);
    return PackageService.get(parameters);
  }

  @AuraEnabled
  public static void saveData(List<Time__c> times, List<Expense__c> expenses, List<SupplierCosts__c> scList) {

    if (times != null) {
        fflib_SObjectDomain.getTriggerEvent(TimeDomain.class).disableAll();
        TimeService.save(new List<Time__c>(times));
    }

    if (expenses != null) {
        fflib_SObjectDomain.getTriggerEvent(Expense.class).disableAll();
        ExpenseService.save(new List<Expense__c>(expenses));
    }

    if (scList != null) {
        fflib_SObjectDomain.getTriggerEvent(SupplierCosts.class).disableAll();
        SupplierCostsService.save(new List<SupplierCosts__c>(scList));
    }

  }

}