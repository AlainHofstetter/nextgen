public interface IContactSelector extends fflib_ISObjectSelector {

    List<Contact> selectById(Set<Id> idSet);

    List<Contact> selectByAccount(Set<Id> accountIds);

    List<Contact> byAbacusVisaNr(Set<String> visaNrs);

}