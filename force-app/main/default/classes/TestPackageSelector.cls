/**
 * Description: Unit test for PackageSelector
 * 
 * Note: Disactivate Process Builder "ProjectOwnerUpdateWithResponsible"
 */
@isTest
public class TestPackageSelector {

    @testSetup
    static void setupTestData() {

        Id acctRecTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('InternalAccount').getRecordTypeId();

        // Account acct = TestFactory.createAccount();
        Account acct = new Account(Name = TestFactory.NAME_ACC + Math.random());
        acct.recordTypeId = acctRecTypeId;
            acct.BillingStreet = 'Av. Del Parque 1';
            acct.BillingCity = 'Madrid';
            acct.BillingPostalCode = '28001';
            acct.BillingCountry = 'Spain';
            acct.LegalNature__c = 'Limited Partnership';
            acct.AccountLanguage__c = 'D';
            insert acct;

        CostCenter__c costC = TestFactory.createCostCenter(acct.Id);
        costC.LegalAccount__c = acct.Id;
        costC.Active__c = true;
        insert costC;

        Contact contact = TestFactory.createContact(acct.Id, costC.Id);
        // contact.UnitRelevance__c = 'GBFR';
        // contact.CostCenter__c = costC.Id;
        insert contact;

        Project__c project = TestFactory.createProject(acct.Id, contact.Id, costC.Id);
        project.TermsOfPayment__c = '1';
        project.ProjectRateHour__c = 110;
        project.ProjectCostCenter__c = costC.Id;
        insert project;

        // Create Packages
        List<Package__c> packages = new List<Package__c>();
        for (Integer i = 0; i < 5; i++) {
            String str_i = String.valueOf(i);
            packages.add(new Package__c(
                Name = 'Test Package ' + str_i,
                ProjectName__c = project.Id,
                PackageSubType__c = 'WorkTime',
                PackageSortNr__c = str_i
            ));
        }
        insert packages;
    }

    @isTest
    static void testSelectAll() {
        IPackageSelector selector = PackageSelector.newInstance();
        List<Package__c> results = selector.selectAll();

        System.assertEquals(5, results.size(), 'Should return 5 packages');
    }

    @isTest
    static void testSelectById() {
        List<Package__c> packages = [SELECT Id FROM Package__c LIMIT 5];
        Set<Id> ids = new Set<Id>();
        for (Package__c pkg : packages) {
            ids.add(pkg.Id);
        }

        IPackageSelector selector = PackageSelector.newInstance();
        List<Package__c> results = selector.selectById(ids);

        System.assertEquals(5, results.size(), 'Should return the packages with given ids');
    }

    @isTest
    static void testSelectByProjectId() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        Set<Id> projectIds = new Set<Id>{project.Id};

        IPackageSelector selector = PackageSelector.newInstance();
        List<Package__c> results = selector.selectByProjectId(projectIds);

        System.assertNotEquals(0, results.size(), 'Should return packages for the given project id');
    }

    @isTest
    static void testSelectBySuperiorExcludedFields() {
        List<Package__c> packages = [SELECT Id FROM Package__c LIMIT 1];
        Set<Id> superiorIds = new Set<Id>{packages[0].Id};
        Set<String> excludedFields = new Set<String>{'Name'};

        IPackageSelector selector = PackageSelector.newInstance();
        List<Package__c> results = selector.selectBySuperiorExcludedFields(superiorIds, excludedFields);

        // System.assertNotEquals(0, results.size(), 'Should return packages excluding specified fields');
    }

    @isTest
    static void testSelectByProjectExcludedFields() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        Set<Id> projectIds = new Set<Id>{project.Id};
        Set<String> excludedFields = new Set<String>{'Name'};

        IPackageSelector selector = PackageSelector.newInstance();
        List<Package__c> results = selector.selectByProjectExcludedFields(projectIds, excludedFields);

        System.assertNotEquals(0, results.size(), 'Should return packages excluding specified fields');
    }

    @isTest
    static void testSelectProjectStructure() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];

        IPackageSelector selector = PackageSelector.newInstance();
        ProjectStructureBean result = selector.selectProjectStructure(project.Id, null, null);

        System.assertNotEquals(null, result, 'Project structure should be returned');
    }

    @isTest
    static void testSelectILVInfo() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];

        IPackageSelector selector = PackageSelector.newInstance();
        ILVCreation result = selector.selectILVInfo(project.Id, null, null);

        System.assertNotEquals(null, result, 'ILV info should be returned');
    }

    @isTest
    static void testSelectFull() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        PackageSelector.Params params = new PackageSelector.Params();
        params.projectId = project.Id;
        params.showTime = true;
        params.showExpense = true;
        params.showSupplierCosts = true;

        IPackageSelector selector = PackageSelector.newInstance();
        PackageSelector.Model model = selector.selectFull(params);

        System.assertNotEquals(null, model, 'Full model should be returned');
    }

}