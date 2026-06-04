public without sharing class TimeExpensesController {

    /*
     * Initial load with user access information
     */
    @AuraEnabled
    public static SObject getInitialUserInfo() {
        return [Select
                    Id,
                    Name,
                    User__r.CanTrackExpensesForOthers__c,
                    User__r.InternalContactID__c,
                    User__r.CanTrackTimeForOthers__c,
                    User__r.IsProjectManager__c,
                    User__r.IsSuperUser__c,
                    User__r.IsManagingDirector__c,
                    User__r.IsHRManager__c,
                    User__r.IsFinanceManager__c,
                    User__r.PS180RoleFinanceApprover__c,
                    LocalCurrency__c
                from Contact
                where User__r.Id = :UserInfo.getUserId()
                limit 1];
    }

    /*
     * Send across record type information
     */
    @AuraEnabled
    public static List<SObject> getExpenseRecordTypes() {
        return [select Id,
        Name from RecordType where SobjectType = 'Expense__c'];
    }

    /*
     * For buttons to work
     */
    @AuraEnabled
    public static Package__c getPackageInformation(Id packageId) {
        return [select Id, RecordType.Name, PackageSubType__c from Package__c where Id = :packageId];
    }

    /*
     * Load the time entries
     */
    @AuraEnabled
    public static List<Time__c> getTimeEntries(String dateRangeStart, String dateRangeEnd, Id filterByUser) {

        String query = 'Select Id, Name, ValNoDelete__c, ProjectName__r.Name, Package__r.PackageStatus__c, ProjectName__r.ProjectStatus__c, ProjectName__r.ProjectPartner__r.Name, ProjectName__r.ProjectPartner__r.Id, ProjectName__r.ProjectSubType__c, ProjectName__r.ProjectNr__c, Package__r.Name, BillingReceiver__r.Name, DurationHhMm__c, DateFrom__c, DateUntil__c, Description__c, StartHhMm__c, EndHhMm__c, ServiceType__c, Timetracker__c, OutOfScope__c, Timetracker__r.Name From Time__c where Id != null ';

        if(filterByUser != null){
            query += ' and Timetracker__c = :filterByUser ';
        }

        if(dateRangeStart != null){
            Date parsedDateRangeStart = date.ValueOf(dateRangeStart);
            query += ' and DateFrom__c >= :parsedDateRangeStart ';
        }

        if(dateRangeEnd != null){
            Date parsedDateRangeEnd = date.ValueOf(dateRangeEnd);
            query += ' and DateFrom__c <= :parsedDateRangeEnd ';
        }

        query += ' Order By DateFrom__c Desc, CreatedDate Desc, ProjectName__r.ProjectNr__c Desc';

        return Database.query(query);

    }

    /*
     * Load the expense entries
     */
    @AuraEnabled
    public static List<Expense__c> getExpenseEntries(String dateRangeStart, String dateRangeEnd, Id filterByUser, Boolean onlyShowPaidPrivately) {

        String query = 'Select Id, Name, ExpenseType__c, ValNoDelete__c, ExpenseValidatedFinance__c, Package__r.PackageStatus__c, ProjectName__r.ProjectStatus__c, ProjectName__r.ProjectPartner__r.Id, ProjectName__r.ProjectPartner__r.Name, ProjectName__r.ProjectSubType__c, ProjectName__r.Name, ProjectName__r.AbacusProjectName__c, ProjectName__r.ProjectNr__c, Package__r.Name, BillingViaCompany__c, BillingViaCompany__r.Name, BillingReceiver__r.Name, Expensetracker__c, Expensetracker__r.Name, Expensetracker__r.CostCenter__r.LegalAccount__r.Name, Expensetracker__r.CostCenter__r.LegalAccount__r.BillingStreetNr__c, Expensetracker__r.CostCenter__r.LegalAccount__r.BillingZip__c, Expensetracker__r.CostCenter__r.LegalAccount__r.BillingCity__c, toLabel(ExpenseSubType__c), toLabel(PaymentType__c), ExpenseDate__c, ExpenseGross__c, SupplierReceiverLocation__c, ListOfNames__c, CreditCardResponsibleCompany__r.Name, CreditCardResponsibleCompany__c, Car__c, Car__r.Name, Distance__c, BusinessReason__c, ProjectName__c, Package__c, LocalCurrency__c From Expense__c where Id != null ';

        if(filterByUser != null){
            query += ' and Expensetracker__c = :filterByUser ';
        }

        if(dateRangeStart != null){
            Date parsedDateRangeStart = date.ValueOf(dateRangeStart);
            query += ' and ExpenseDate__c >= :parsedDateRangeStart ';
        }

        if(dateRangeEnd != null){
            Date parsedDateRangeEnd = date.ValueOf(dateRangeEnd);
            query += ' and ExpenseDate__c <= :parsedDateRangeEnd ';
        }

        if(onlyShowPaidPrivately == true) {
            query += ' and PaymentType__c = \'Private\'';
        }

        query += ' Order By ExpenseDate__c Desc, ProjectName__r.ProjectNr__c Desc';

        return Database.query(query);

    }

    /*
     * Method to save multiple time entries
     */
    @AuraEnabled
    public static List<Time__c> saveTimeEntries(List<Time__c>  timeEntries) {

        // check if fist entry has id
        Time__c firstEntry = timeEntries.get(0);
        if(firstEntry.Id != null){
            // then update
            update timeEntries;
        }
        else {
            // or insert
            insert timeEntries;
        }

        return timeEntries;

    }

    /*
     * Deleting a time entry
     */
    @AuraEnabled
    public static Time__c deleteTimeEntry(Time__c timeEntry) {
        delete timeEntry;
        return timeEntry;
    }

    /*
     * Method to save the expense entries
     */
    @AuraEnabled
    public static List<Expense__c> saveExpenseEntries(List<Expense__c> expenseEntries) {
        /* upsert expenseEntries; */
        ExpenseService.save(new List<Expense__c>(expenseEntries));
        return expenseEntries;
    }

    /*
     * Deleting an expense entry
     */
    @AuraEnabled
    public static Expense__c deleteExpenseEntry(Expense__c expenseEntry) {
        delete expenseEntry;
        return expenseEntry;
    }


    @AuraEnabled
    public static Map<String, String> getPaymentTypes() {
      return Utils.getPicklistEntries(Expense__c.PaymentType__c);
    }

    @AuraEnabled
    public static Map<String, String> getExpenseSubtypes() {
      return Utils.getPicklistByRecordType(Expense__c.ExpenseSubType__c, 'Expense__c.Receipt');
    }

    /*
     * Load the Currency Type with Rates
     */
    @AuraEnabled
    public static List<CurrencyType> getCurrencyTypeWithRates()
    {
        List<CurrencyType> currencyTypes = new List<CurrencyType>([SELECT Id, IsActive, ISOCode, ConversionRate
                                                                   FROM CurrencyType
                                                                   WHERE IsActive = TRUE]);
        if(!currencyTypes.isEmpty())
        {
            return currencyTypes;
        }else{

            return null;
        }

    }
}