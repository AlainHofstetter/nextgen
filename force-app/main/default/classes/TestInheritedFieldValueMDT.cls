@IsTest
public class TestInheritedFieldValueMDT {

  @IsTest
  private static void callingGoShouldNotRegisterDirty() {

    // Create mock
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);

    // Given
    Invoice__c inv = new Invoice__c(
        ProjectName__c = fflib_IDGenerator.generate(Project__c.SObjectType),
        InvoiceDescription__c = 'Test'
    );
    List<InheritedFieldValue__mdt> meta =  new InheritedFieldValueMDTSelector().getInheritedFieldValueMDTTest();
    Application.UnitOfWork.setMock(uowMock);

    // When
    IInheritedFieldValueMDT domain = InheritedFieldValueMDT.newInstance(meta);
    domain.go(uowMock, new List<SObject> {inv});

    // Then

  }


}