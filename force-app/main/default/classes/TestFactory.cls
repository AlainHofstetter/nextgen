@isTest
public class TestFactory
{
	public static final String NAME_ACC = 'Test';

	public static Account createAccount()
	{
		Account acc = new Account(Name = NAME_ACC + Math.random());
		acc.BillingStreet = 'Queen St 1';
		acc.BillingCity = 'Wollongong';
		//acc.BillingState = 'NSW';
		acc.BillingPostalCode = '2046';
		acc.BillingCountry = 'SWITZERLAND';
		acc.LegalNature__c = 'Corporation / Limited Company';
		acc.AccountLanguage__c = 'D';
		acc.LocationCity__c = 'Wollongong';
		acc.LocationZip__c = '2046';
		acc.LocationCountry__c = 'SWITZERLAND';
		acc.LocationStreetNr__c = 'Queen St 1';
		acc.LocationPoBox__c = 'test';
		acc.Phone = '+34777444666';
		acc.UID__c = 'CHE-108.113.625';
		
		insert acc;
		return acc;
	}

	public static Opportunity createOpportunity(Account acc, Id pricebookId)
	{
		Opportunity opp = new Opportunity(Name = NAME_ACC+String.valueOf(Math.random()*10000));
		opp.AccountId = acc.id;
		opp.CloseDate = system.Today();
		opp.StageName = 'Enquiry Details';
		opp.Pricebook2Id = pricebookId;
		
		insert opp;
		return opp;
	}

	public static OpportunityLineItem createOppLineItem(Opportunity opp, Product2 product)
	{
		return createOppLineItem(opp, product, true);
	}

	public static OpportunityLineItem createOppLineItem(Opportunity opp, Product2 product, Boolean doCommit)
	{
		PricebookEntry pbE = getPricebookEntry(product, opp.Pricebook2Id);

		OpportunityLineItem oli = new OpportunityLineItem(
										OpportunityId = opp.Id, 
										Product2Id = product.Id, 
										PricebookEntryId =pbE.Id, 
										TotalPrice = 30, 
										Quantity = 1);
		if (doCommit)
		{
			insert oli;
		}
		return oli;
	}


	public static PricebookEntry getPricebookEntry(Product2 prod, Id pricebookId)
	{
		//Id pricebookId = Test.getStandardPricebookId();
		PricebookEntry pbEntry = new PricebookEntry(
									Pricebook2Id = pricebookId,
									Product2Id = prod.Id,
									UnitPrice = 100.00,
									IsActive = true);
		insert pbEntry;
		return pbEntry;
	}

	public static Pack__c createPackage(Id pricebookId)
	{
		Pack__c pack = new Pack__c( Name = 'pack1',
							Description__c = 'TESTDescription ' + Math.random(),
							PriceBook__c = pricebookId,
							SortNumber__c = 'Test Sort');
		insert pack;
		return pack;
	}


	public static Product2 createProduct()
	{
		return createProduct(true);
	}

	public static Product2 createProduct(Boolean doCommit)
	{
		Product2 p = new Product2(Name = 'Product'+String.valueOf(Math.random()*10000), isActive = true );
		if (doCommit)
		{
			insert p;
		}
		return p;
	}

	public static PackageLine__c createPackageLine(Pack__c pack,Product2 prod)
	{
		PackageLine__c packLine = new PackageLine__c(
										Defaultprice__c = 20,
										Defaultquantity__c = 2,
										Package__c = pack.Id,
										Product__c = prod.Id,
										ProductType__c = 'Hours');
		insert packLine;
		return packLine;
	}

	public static Quote createQuote(Opportunity opp)
	{
		Quote q = new Quote(Name = NAME_ACC+String.valueOf(Math.random()*10000), 
									OpportunityId = opp.Id, 
									Pricebook2Id = opp.Pricebook2Id );
		insert q;
		return q; 
	}

	public static QuoteLineItem createQuoteLineItem(Quote q, Product2 product)
	{
		return createQuoteLineItem(q, product, true);
	}

	public static QuoteLineItem createQuoteLineItem(Quote q, Product2 product, Boolean doCommit)
	{
		PricebookEntry pbE = getPricebookEntry(product, q.Pricebook2Id);
		QuoteLineItem qli = new QuoteLineItem(
									QuoteId = q.Id, 
									Product2Id = product.Id, 
									Quantity = 1, 
									PricebookEntryId =pbE.Id, 
									UnitPrice = 10); 
		if (doCommit)
		{
			insert qli;
		}
		return qli;
	}

	public static OpportunityPackage__c createOpportunityPackage(Opportunity opp, Pack__c bundlePackage)
	{
		OpportunityPackage__c result = new OpportunityPackage__c();
		result.BundlePackage__c = bundlePackage.Id;
		result.Opportunity__c = opp.Id;
		insert result;
		return result;
		//oP.SortNumber__c = currentWrapper.sortNumber;
		//oP.TotalAmmount__c = Double.valueOf(currentWrapper.totalPrice);
	}

	public static Quote_Package__c createQuotePackage(Quote quote, Pack__c bundlePackage)
	{
		Quote_Package__c result = new Quote_Package__c();
		result.Bundle_Package__c = bundlePackage.Id;
		result.Quote__c = quote.Id;
		insert result;
		return result;
		//oP.SortNumber__c = currentWrapper.sortNumber;
		//oP.TotalAmmount__c = Double.valueOf(currentWrapper.totalPrice);
	}

	public static Invoice__c createInvoice(Id accId, Id projId, Id costCenter){
		Invoice__c inv = new Invoice__c();
		inv.BillingViaCompany__c = accId;
		inv.ProjectName__c = projId;
		inv.ProjectCostCenter__c = costCenter;
		inv.ESRAccountNr__c = '01-8513-5';
		inv.ESRMergentNr__c = '207115';
		inv.InvoiceDocumentNr__c = 25010829;
		return inv;
	}

	public static Project__c createProject(Id accId,Id contId, Id costC){
		Project__c proj = new Project__c();
		proj.BillingViaCompany__c = accId;
		proj.Name = 'Testing project';
		proj.ContractPartner__c = accId;
		proj.ProjectResponsibleBusiness__c = contId;
		proj.ProjectStartDate__c = System.Today();
		proj.ProjectSubType__c = 'Support';
		proj.ProjectCostCenter__c = costC;
		return proj;

	}

	public static Contact createContact(Id accId, Id costCenter){
		Contact cont = new Contact();
		Id contactRT = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('InternalContact').getRecordTypeId();
		cont.recordTypeId = contactRT;
		cont.FirstName ='Test ' + + Math.random();
		cont.LastName ='Test ' + + Math.random();
		cont.AccountId = accId;
		cont.UnitRelevance__c = 'GBCH';
		cont.Phone = '+41666444444';
		cont.CostCenter__c = costCenter;
		cont.User__c = UserInfo.getUserId();
		cont.Email = 'test' + Math.random() + '@sdf.com';
		return cont;
	}

	public static CostCenter__c createCostCenter(Id accId){
		CostCenter__c costC = new CostCenter__c();
		costC.Name = 'Test';
		costC.ClearingCostCenterNr__c = '456';
		costC.CostCenterNr__c = '456';
		costC.LegalAccount__c = accId;
		costC.CHFIBAN__c = 'ES76 2077 0024 0031 0257 5766';
		costC.CHFQRIBAN__c = 'ES76 2077 0024 0031 0257 5766';
		costC.Active__c = true;
		return costC;
	}

	public static InvoicePos__c createInvoicePosition(Id invoiceId, Id invSuperior, Id serviceId, Id finAccId){
		InvoicePos__c invPos = new InvoicePos__c();
		invPos.InvoiceName__c = invoiceId;
		invPos.InvoicePositionName__c = 'Invoice Position ' + Math.random();
		if(invSuperior != null){
			invPos.InvoicePositionSuperior__c = invSuperior;
		}
		invPos.InvoicePositionAmount__c = Math.random();
		invPos.PackageName__c = serviceId;
		invPos.FinanceAccount__c = finAccId;
		invPos.ShowPosition__c = true;
		return invPos;
	}

	public static Package__c createService(Id projectId){
		Package__c service = new Package__c();
		service.ProjectName__c = projectId;
		return service;
	}

	public static FinanceAccount__c createFinanceAccount(Id costCenterId) {
		FinanceAccount__c finAcc = new FinanceAccount__c();
		finAcc.Name = 'Test Fin Acct';
		finAcc.CostCenter__c = costCenterId;
		finAcc.FinanceAccountNr__c = '3611';
		finAcc.FinanceClearingNr__c = '3657';
		finAcc.TypeName__c = 'SupplierCosts';
		finAcc.TypeName2__c = 'AbacusInbox';

		return finAcc;
	}

	public static void makeData(){
		Account acc = TestFactory.createAccount();
		Id recTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('InternalAccount').getRecordTypeId();
		acc.RecordTypeId = recTypeId;
		update acc;
		CostCenter__c costCenter = TestFactory.createCostCenter(acc.Id);
		insert costCenter;

		Contact contact = TestFactory.createContact(acc.Id, costCenter.Id);
		insert contact;
		
		
		Project__c proj = TestFactory.createProject(acc.Id, contact.Id, costCenter.Id);
		proj.TermsOfPayment__c = '1';
		proj.ProjectRateHour__c = 10;
		insert proj;

		FinanceAccount__c finAcc = TestFactory.createFinanceAccount(costCenter.Id);
		insert finAcc;

		Id serviceRtId = Schema.SObjectType.Package__c.getRecordTypeInfosByDeveloperName().get('Time').getRecordTypeId();
		Package__c  service = TestFactory.createService(proj.Id);
		service.RecordTypeId = serviceRtId;
		service.PackageSubType__c = 'WorkTime';
		System.debug('---TestFactory.makeData--- service: '+service);
		insert service;    
	 }
}