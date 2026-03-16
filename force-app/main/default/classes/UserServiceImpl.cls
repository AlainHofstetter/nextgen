public with sharing class UserServiceImpl implements IUserService {

  public User getLogged() {
    return UserSelector.newInstance().selectById(UserInfo.getUserId());
  }

}