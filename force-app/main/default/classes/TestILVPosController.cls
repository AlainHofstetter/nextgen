@IsTest
private class TestILVPosController {

  @IsTest
  private static void callingGetProjectStructureShouldCallService() {

    // Create Mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();

    // Given
    Id projectId = fflib_IDGenerator.generate(Project__c.SObjectType);
    Mocks.ILVPosService mockInvoiceService = new Mocks.ILVPosService(mocks);
    Application.Service.setMock(IILVPosService.class, mockInvoiceService);

    // When
    ILVPosController.get(projectId, '2016-12-01', '2016-12-01');

    // Then
    ((IILVPosService) mocks.verify(mockInvoiceService)).get(projectId, '2016-12-01', '2016-12-01');

  }

  @IsTest
  private static void callingSaveShouldCallService() {

    // Create Mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();

    // Given
    Mocks.ILVPosService mockInvoiceService = new Mocks.ILVPosService(mocks);
    Application.Service.setMock(IILVPosService.class, mockInvoiceService);

    // When
    ILVPosController.save(new Invoice__c(), new List<ILVPos__c>());

    // Then
    ((IILVPosService) mocks.verify(mockInvoiceService)).save(new Invoice__c(), new List<ILVPos__c>());

  }

  @IsTest
  private static void test_startQueueableJob() {

    // Create Mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();

    // Given
    Mocks.ILVPosService mockInvoiceService = new Mocks.ILVPosService(mocks);
    Application.Service.setMock(IILVPosService.class, mockInvoiceService);

	  Test.startTest();

	  // When — pass one position so the queueable's chunk loop has something to process
	  Id jobId = ILVPosController.startQueueableJob(new Invoice__c(), new List<ILVPos__c>{new ILVPos__c()});
	  System.assertNotEquals(null, jobId);

	  Boolean isJobFinished = ILVPosController.checkIsJobFinished(jobId);
	  System.assertEquals(false, isJobFinished);

	  Test.stopTest();

	  isJobFinished = ILVPosController.checkIsJobFinished(jobId);
	  System.assertEquals(true, isJobFinished);

    // Then — verify save was called with the single position that was enqueued
    ((IILVPosService) mocks.verify(mockInvoiceService)).save(new Invoice__c(), new List<ILVPos__c>{new ILVPos__c()});

  }

}