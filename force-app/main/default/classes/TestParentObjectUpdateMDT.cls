@IsTest
public class TestParentObjectUpdateMDT {

  @IsTest
  private static void callingGoShouldRegisterDirty() {

    // Create mock
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);

    // Given
    List<ParentObjectUpdate__mdt> meta = new ParentObjectUpdateMDTSelector().getParentObjectMDTTest();
    Contact c = new Contact(
        Id = fflib_IDGenerator.generate(Contact.SObjectType),
        User__c = fflib_IDGenerator.generate(User.SObjectType)
    ); // child

    Application.UnitOfWork.setMock(uowMock);

    // When
    IParentObjectUpdateMDT domain = ParentObjectUpdateMDT.newInstance(meta);
    domain.go(uowMock, new List<SObject> {c}, null);

    // Then
    ((fflib_ISObjectUnitOfWork)
     mocks.verify(uowMock)).registerDirty(
          fflib_Match.sObjectWith(
            new Map<SObjectField, Object> {
              User.InternalContactID__c => c.Id
            }
          )
     );

  }


}