@isTest
private class TestUser {

  @IsTest
  private static void testUpdatePermissionSets() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);
    IPermissionSetAssignmentSelector permSelectorMock = new Mocks.PermissionSetAssignmentSelector(mocks);
    IPermissionSetAssignmentMDTSelector permMDTMock = new Mocks.PermissionSetAssignmentMDTSelector(mocks);
    IPermissionSetAssignmentMDT domainMock = new Mocks.PermissionSetAssignmentMDT(mocks);

    //Given
    mocks.startStubbing();
    mocks.when(permSelectorMock.sObjectType()).thenReturn(PermissionSetAssignment.SObjectType);
    mocks.when(permSelectorMock.selectByUserId(new Set<Id>())).thenReturn(new List<PermissionSetAssignment>());
    mocks.when(permMDTMock.sObjectType()).thenReturn(PermissionSetAssigment__mdt.SObjectType);
    mocks.when(permMDTMock.selectBySourceObj(fflib_Match.anyString())).thenReturn(new List<PermissionSetAssigment__mdt>());
    mocks.when(domainMock.sObjectType()).thenReturn(PermissionSetAssigment__mdt.SObjectType);
    mocks.stopStubbing();
    Application.UnitOfWork.setMock(uowMock);
    Application.Selector.setMock(permSelectorMock);
    Application.Selector.setMock(permMDTMock);
    Application.Domain.setMock(domainMock);

    // When
    new UserDomain(new List<User> ()).updatePermissionSets();

    // Then
    ((IPermissionSetAssignmentSelector) mocks.verify(permSelectorMock)).selectByUserId(new Set<Id>());
    ((IPermissionSetAssignmentMDTSelector) mocks.verify(permMDTMock)).selectBySourceObj(fflib_Match.anyString());
    ((IPermissionSetAssignmentMDT) mocks.verify(domainMock)).applyPermissionSets(uowMock, new List<SObject>(), new List<PermissionSetAssignment>());
    ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock)).commitWork();
  }

}