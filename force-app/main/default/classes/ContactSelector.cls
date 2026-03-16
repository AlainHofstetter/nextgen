public class ContactSelector extends fflib_SObjectSelector
    implements IContactSelector {

    public static IContactSelector newInstance() {
        return (IContactSelector) Application.Selector.newInstance(Contact.SObjectType);
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            Contact.Id,
            Contact.Email,
            Contact.AbacusDefaultTimeType__c,
            Contact.AbacusVisaNr__c
        };
    }

    public Schema.SObjectType getSObjectType() {
        return Contact.sObjectType;
    }

    public List<Contact> selectById(Set<Id> idSet) {
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('id in :idSet');

        return (List<Contact>) Database.query(query.toSOQL());
    }

    public List<Contact> selectByAccount(Set<Id> accountIds) {
        fflib_QueryFactory query = newQueryFactory(false);
        query.selectField('Id');
        query.selectField('Name');
        query.selectField('Account.Name');
        query.selectField('AccundId');

        query.addOrdering('LastName', fflib_QueryFactory.SortOrder.ASCENDING);
        query.addOrdering('FirstName', fflib_QueryFactory.SortOrder.ASCENDING);

        query.setCondition('AccoundId in :accountIds');
        return (List<Contact>) Database.query(query.toSOQL());
    }

    public List<Contact> byAbacusVisaNr(Set<String> visaNrs) {
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('AbacusVisaNr__c in :visaNrs');
        return (List<Contact>) Database.query(query.toSOQL());
    }

}