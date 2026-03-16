public with sharing class UserService {

  private static IUserService service() {
    return (IUserService) Application.Service.newInstance(IUserService.class);
  }

  public static User getLogged() {
    return service().getLogged();
  }

}