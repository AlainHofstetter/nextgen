public with sharing class InheritedFieldValueMDT extends fflib_SObjectDomain
	implements IInheritedFieldValueMDT {

	public static IInheritedFieldValueMDT newInstance(List<InheritedFieldValue__mdt> records) {
		return (IInheritedFieldValueMDT) Application.Domain.newInstance(records);
	}

	public InheritedFieldValueMDT(List<InheritedFieldValue__mdt> records) {
		super(records);
	}

	public void go(fflib_ISObjectUnitOfWork uow, List<SObject> targets) {

		Map<String, fflib_QueryFactory> qFactories = new Map<String, fflib_QueryFactory>();
		Map<String, List<InheritedFieldValue__mdt>> inheritedFVMap = new Map<String, List<InheritedFieldValue__mdt>>();
		Map<String, Set<String>> relatedFieldMap = new Map<String, Set<String>>();

		for (InheritedFieldValue__mdt ifv: (List<InheritedFieldValue__mdt>) records) {

			for (SObject obj: targets) {

				Boolean isInsert = System.Test.isRunningTest() ? true : Trigger.isInsert; // trick for running our test

				//if UserValuesWinsOnInsert__c == true, this is a new record getting inserted and there is a supplied value from the user then don't inherit a value
				if(ifv.UserValuesWinsOnInsert__c == true && isInsert && obj.get(ifv.TargetField__r.APIName__c) != null){
					continue;
				}


				if ((ifv.Insert__c == true && isInsert) || (ifv.Update__c == true && Trigger.isUpdate)) {
					SObjectType sourceObjectType = Schema.getGlobalDescribe().get(ifv.SourceObject__r.APIName__c);
					fflib_QueryFactory qf = qFactories.get(ifv.SourceObject__r.APIName__c);

					if (qf == null) {
						qf = new fflib_QueryFactory(sourceObjectType);
						qFactories.put(ifv.SourceObject__r.APIName__c, qf);
					}

					qf.selectField(ifv.SourceQuery__c);

					String relatedField = (String) obj.get(ifv.RelationshipField__r.APIName__c);
					Set<String> relatedFields = relatedFieldMap.get(ifv.SourceObject__r.APIName__c);
					if (relatedFields == null) {
						relatedFieldMap.put(ifv.SourceObject__r.APIName__c, new Set<String>{relatedField});
					} else {
						relatedFields.add(relatedField);
					}

					List<InheritedFieldValue__mdt> ifvList = inheritedFVMap.get(ifv.SourceObject__r.APIName__c);
					if (!(obj.get(ifv.RelationshipField__r.APIName__c) instanceof Id)) {
						continue;
					}
					if (ifvList == null || ifvList.isEmpty()) {
						inheritedFVMap.put(ifv.SourceObject__r.APIName__c, new List<InheritedFieldValue__mdt> {ifv});
					} else {
						ifvList.add(ifv);
					}
				}
			}

		}

		Set<String> factoryKeys = qFactories.keySet();
		for (String key: factoryKeys) { 

			fflib_QueryFactory qf = qFactories.get(key);
			Set<String> relatedFields = relatedFieldMap.get(key);
			qf.setCondition('Id IN :relatedFields');
			System.debug('queryLook: '+qf.toSOQL());
			Map<Id, SObject> sourceObjsMap = new Map<Id, SObject>(Database.query(qf.toSOQL()));

			if (sourceObjsMap.size() > 0) {
				for (SObject obj: targets) {
					for (InheritedFieldValue__mdt ifv: inheritedFVMap.get(key)) {
						SObject sourceObject = sourceObjsMap.get((Id) obj.get(ifv.RelationshipField__r.APIName__c));
						if (sourceObject != null) {
							obj.put(ifv.TargetField__r.APIName__c, Utils.getSObjectValue(sourceObject, ifv.SourceQuery__c));
						}
					}

					if (uow != null) uow.registerDirty(obj);

				}
			}

		}

	}

	public class Constructor implements fflib_SObjectDomain.IConstructable {
		public fflib_SObjectDomain construct(List<SObject> sObjectList) {
			return new InheritedFieldValueMDT(sObjectList);
		}
	}

}