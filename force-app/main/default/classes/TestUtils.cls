@IsTest
private class TestUtils {

    @IsTest
    private static void testListToMap() {
        List<Contact> contacts = new List<Contact>{
                new Contact(AccountId = fflib_IDGenerator.generate(Account.SObjectType))
        };
        Map<Id, SObject> newMap = Utils.listToMap(Contact.AccountId, contacts);
        System.assert(newMap.containsKey(contacts[0].AccountId));
    }

    @IsTest
    private static void testListToMapLists() {
        Account acc = new Account(Id = fflib_IDGenerator.generate(Account.SObjectType));
        Contact con = new Contact(Id = fflib_IDGenerator.generate(Contact.SObjectType), AccountId = acc.Id);
        con.Account = acc;
        List<Contact> contacts = new List<Contact> {con};

        Map<Id, List<SObject>> newMap = Utils.listToMapLists('Account.Id', contacts);
        System.assert(newMap.get(acc.Id)[0].Id == con.Id);
    }

    @IsTest
    private static void testGetPicklist() {
        List<String> values = Utils.getPicklist(Contact.CurrencyIsoCode);
        System.assert(values.size() > 0);
    }

    @IsTest
    private static void testFormatDate() {
        Date d = Date.newInstance(1989, 11, 26);
        System.assertEquals(Utils.formatDate(d, 'yyyy-MM-dd'), '1989-11-26');
    }

}