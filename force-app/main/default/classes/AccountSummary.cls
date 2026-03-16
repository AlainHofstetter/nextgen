public with sharing class AccountSummary extends CommonSummary
{
	/**
	*	@description Generates an instance to be used for summary run.
	*/
	public static AccountSummary getInstance()
	{
		CommonSummary.ChildInfo aUnitRelationInfo = new CommonSummary.ChildInfo('Segmentations__r', new List<String>{'Id', 'Customer__c',
				'Supplier__c', 'Partner__c', 'AccountManager__c', 'Deputy__c', 'RecordType.Name', 'AccountManager__r.FirstName',
				'AccountManager__r.LastName', 'Deputy__r.FirstName', 'Deputy__r.LastName'}, null);
		return new AccountSummary(null, new List<CommonSummary.ChildInfo>{aUnitRelationInfo});
	}
	
	/**
	*	@description basic constructor.
	*/
	private AccountSummary(al.ConditionGroup theParentConditions, List<ChildInfo> theChildInfoList)
	{
		super('Account', null, theParentConditions, theChildInfoList);
	}
	
	/**
	*	@description 
	*/
	protected override sObject performCalculation(sObject theParent, Map<String, List<sObject>> theChildMap)
	{
		Account aResult = new Account(Id = theParent.Id);
		Map<String, Set<String>> aFieldsMapping = new Map<String, Set<String>>();
		for (String aField: new Set<String>{'CustomerActual__c', 'Supplier__c', 'Partner__c', 'AccountManager__c', 'Deputy__c'})
		{
			aFieldsMapping.put(aField, new Set<String>());
		}
		List<sObject> anUnitiChildren = theChildMap.get('Segmentations__r');
		if (anUnitiChildren != null)
		{
			for (UnitRelation__c aRel: (List<UnitRelation__c>) anUnitiChildren)
			{
				if (aRel.Customer__c == 'Actual')
				{
					aFieldsMapping.get('CustomerActual__c').add(aRel.RecordType.Name);
				}
				if (aRel.Supplier__c == true)
				{
					aFieldsMapping.get('Supplier__c').add(aRel.RecordType.Name);
				}
				if (aRel.Partner__c == true)
				{
					aFieldsMapping.get('Partner__c').add(aRel.RecordType.Name);
				}
				if (aRel.AccountManager__c != null)
				{
					Contact anAccManager = aRel.AccountManager__r;
					aFieldsMapping.get('AccountManager__c').add(getShortName(anAccManager));
				}
				if (aRel.Deputy__c != null)
				{
					Contact aDeputy = aRel.Deputy__r;
					aFieldsMapping.get('Deputy__c').add(getShortName(aDeputy));
				}
			}
		}
		for (String aField:aFieldsMapping.keySet())
		{
			Set<String> aValues = aFieldsMapping.get(aField);
			List<String> aValueList = new List<String>();
			aValueList.addAll(aValues);
			aValueList.sort();
			String aValue = String.join(aValueList, '; ');
			aResult.put(aField, aValue);
		}
		return aResult;
	}
	
	/**
	*	@description Returns an alias name of contact.
	*/
	public static String getShortName(Contact theContact)
	{
		String aShortName = (theContact.FirstName == null ? '' :(theContact.FirstName.substring(0, 1).toUpperCase())) + theContact.LastName;
		aShortName = aShortName.length() > 8 ? aShortName.substring(0, 8) : aShortName;
		return aShortName;
	}
}