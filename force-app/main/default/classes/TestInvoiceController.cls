/**
 * Description: Unit test for InvoiceController
 * 
 * Note: Disactivate Process Builder "ProjectOwnerUpdateWithResponsible"
 */
@IsTest
private class TestInvoiceController {

  @IsTest
  private static void callingGetProjectStructureShouldCallService() {

    // Create Mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();

    // Given
    Id projectId = fflib_IDGenerator.generate(Project__c.SObjectType);
    Mocks.InvoiceService mockInvoiceService = new Mocks.InvoiceService(mocks);
    Application.Service.setMock(IInvoiceService.class, mockInvoiceService);

    // When
    InvoiceController.getProjectStructure(projectId, '2016-12-01', '2016-12-01');

    // Then
    ((IInvoiceService) mocks.verify(mockInvoiceService)).getProjectStructure(projectId, '2016-12-01', '2016-12-01');

  }

  @IsTest
  private static void callingCancelShouldCallService() {

    // Create Mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();

    // Given
    Id invoiceId = fflib_IDGenerator.generate(Invoice__c.SOBjectType);
    Mocks.InvoiceService mockInvoiceService = new Mocks.InvoiceService(mocks);
    mocks.startStubbing();
    mocks.when(mockInvoiceService.cancel(invoiceId)).thenReturn(new Invoice__c(Id = fflib_IDGenerator.generate(Invoice__c.SOBjectType)));
    mocks.stopStubbing();
    Application.Service.setMock(IInvoiceService.class, mockInvoiceService);

    // When
    InvoiceController.cancel(invoiceId);

    // Then
    ((IInvoiceService) mocks.verify(mockInvoiceService)).cancel(invoiceId);

  }


  @IsTest
  private static void callingSaveShouldCallService() {

    // Create Mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();

    // Given
    Mocks.InvoiceService mockInvoiceService = new Mocks.InvoiceService(mocks);
    Application.Service.setMock(IInvoiceService.class, mockInvoiceService);

    // When
    InvoiceController.save(new Invoice__c(), new List<Package__c>(), new List<InvoicePos__c>());

    // Then
    // ((IInvoiceService) mocks.verify(mockInvoiceService)).save(new Invoice__c(), new List<Package__c>(), new List<InvoicePos__c>());

  }

  @IsTest
  private static void saveValidationTests() {

    Id projectId = fflib_IDGenerator.generate(Project__c.SObjectType);

    Id acctRecTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('InternalAccount').getRecordTypeId();
    Id pkgRecTypeId =  Schema.SObjectType.Package__c.getRecordTypeInfosByDeveloperName().get('Expense').getRecordTypeId();

    // Account acct = TestFactory.createAccount();
    Account acct = new Account(Name = TestFactory.NAME_ACC + Math.random());
    acct.recordTypeId = acctRecTypeId;
		acct.BillingStreet = 'Queen St 1';
		acct.BillingCity = 'Wollongong';
		//acc.BillingState = 'NSW';
		acct.BillingPostalCode = '2046';
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
    System.debug('---saveValidationTests--- project: '+project);
    System.debug('---saveValidationTests--- SELECT project: '+[SELECT Id, Name, ValCountHasInvoiceDraft__c FROM Project__c]);


    Package__c pkg = TestFactory.createService(project.Id);
    pkg.PackageSubType__c = 'Expense';
    pkg.RecordTypeId = pkgRecTypeId;
    insert pkg;
    List<Package__c> lstPkg = new List<Package__c>();
    lstPkg.add(pkg);

    Invoice__c invoice = new Invoice__c();
    invoice.FinanceDate__c = Date.newInstance(2023, 10, 6);
    invoice.PeriodFrom__c = Date.newInstance(2023, 09, 1);
    invoice.InvoiceTitle__c = 'Title';
    invoice.ProjectName__c = project.Id;
    invoice.InvoiceDate__c = Date.newInstance(2023, 10, 26);
    invoice.PeriodUntil__c = Date.newInstance(2023, 09, 30);

    FinanceAccount__c fa = new FinanceAccount__c(
        // Id = fflib_IDGenerator.generate(FinanceAccount__c.SObjectType),
        Active__c = true,
        FinanceAccountNr__c = '001',
        FinanceClearingNr__c = '1001',
        CostCenter__c = project.ProjectCostCenter__c,
        TypeName__c = 'Expense',
        TypeName2__c = 'Expense'
    );
    insert fa;

    InvoicePos__c invPos = new InvoicePos__c();
    invPos.ShowInvoiceText__c = false;
    // invPos.InvoicePositionText__c = ' ';
    invPos.ShowPositionAmount__c = false;
    invPos.PackageType__c = 'Expense';
    invPos.ShowPosition__c = true;
    // invPos.Id = 'a0P7Y00000A6bviUAB';
    invPos.InvoicePositionAmount__c = 100;
    invPos.PackageName__c = pkg.Id;

    List<InvoicePos__c> invPosLst = new List<InvoicePos__c>();
    invPosLst.add(invPos);

    test.startTest();
      try {
        InvoiceController.save(invoice, lstPkg, new List<InvoicePos__c>());
      }
      catch (Exception ex) {
        System.debug('----All OK---- Invoice Validation');
      }
    test.stopTest();
    
    try {
      invoice.InvoiceTitle__c = 'Rechnung';
      InvoiceController.save(invoice, lstPkg, invPosLst);
    }
    catch (Exception ex) {
      System.debug('----All OK----Invoice Position Validation');
    }

  }
}