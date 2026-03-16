@IsTest
private class TestUserService {

  @IsTest
  private static void callingServiceShouldCallSelectorAndGetLoggedUser() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    IUserSelector selectorMock = new Mocks.UserSelector(mocks);

    // Given
    mocks.startStubbing();
    mocks.when(selectorMock.sObjectType()).thenReturn(User.SObjectType);
    mocks.when(selectorMock.selectById(fflib_Match.anyId())).thenReturn(new User());
    mocks.stopStubbing();
    Application.Selector.setMock(selectorMock);

    // When
    UserService.getLogged();

    // Then
    ((IUserSelector) mocks.verify(selectorMock)).selectById(fflib_Match.anyId());

  }

}