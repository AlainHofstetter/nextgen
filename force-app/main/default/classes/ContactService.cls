/**
*	@description Contact service. Class contains methods to change Contact records. 
*
*	@author dch
*	@copyright PARX
*/
public with sharing class ContactService 
{
	/**
	*	@description Set of filds that should be set to null once we attach contact to Account with "Summary Account" record type.
	*/
	private static Set<String> SUMMARY_CONTACT_NULL_FIELDS = new Set<String>{'Department', 'Email', 'Fax', 'MobilePhone', 'Phone', 
			'ReportsToId', 'Function__c', 'JobTitle__c', 'LocationAddressLine2__c', 'LocationAddressLine3__c', 'LocationCity__c', 
			'LocationCountry__c', 'LocationPoBox__c', 'LocationState__c', 'LocationStreetNr__c', 'LocationZip__c', 'OtherAddressLine2__c', 
			'OtherAddressLine3__c', 'OtherCity__c', 'OtherCountry__c', 'OtherPoBox__c', 'OtherState__c', 'OtherStreetNr__c', 'OtherZip__c'};

	/**
	*	@description Set of filds that should be set to null once we attach contact to Account with "Private Account" record type.
	*/
	public static Set<String> PRIVATE_CONTACT_NULL_FIELDS = new Set<String>{'OtherAddressLine2__c', 
			'OtherAddressLine3__c', 'OtherCity__c', 'OtherCountry__c', 'OtherPoBox__c', 'OtherState__c', 'OtherStreetNr__c', 'OtherZip__c',
			'Department', 'ReportsToId'};
	
	/**
	*	@description method is used query accounts to check account record type and call method to set right fields to null.
	*/
	public static void defineAccountRecordType(Set<sObject> contactsWithNewAccount)
	{
		Map<Id, List<Contact>> accountToContacts = Utils.getParentToChilrenMap('AccountId', contactsWithNewAccount);
		List<Account> accounts = [SELECT RecordTypeId FROM Account WHERE Id IN :accountToContacts.keySet()];
		for (Account account : accounts)
		{
			if (account.RecordTypeId == Utils.recordTypes.get('Account:Summary_Account'))
			{
				setContactsFieldsToNullValue(accountToContacts.get(account.Id), SUMMARY_CONTACT_NULL_FIELDS);
			} else if (account.RecordTypeId == Utils.recordTypes.get('Account:PrivateAccount'))
			{
				setContactsFieldsToNullValue(accountToContacts.get(account.Id), PRIVATE_CONTACT_NULL_FIELDS);
			}
		}
	}
	
	/**
	*	@description method is used to set target contacts specified fields to null.
	*/
	private static void setContactsFieldsToNullValue(List<Contact> contacts, Set<String> fields)
	{
		for (Contact contact : contacts)
		{
			//contact.RecordTypeId = Utils.recordTypes.get('Contact:PrivateContact');
			for (String field : fields)
			{
				contact.put(field, null);
			}
		}
	}
}