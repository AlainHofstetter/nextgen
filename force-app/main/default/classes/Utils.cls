/**
 *	@description Class contains some useful features, that can be used in triggers and controllers.
 *
 *	@author akr
 *	@copyright PARX
 */
public without sharing class Utils {
	public static Set<Id> getModifiedObjectParents(List<String> theFieldsList, String theParentFild,
		List<sObject> theObjects, Map<Id, sObject> theOldObjects) {
		Set<Id> aResult = new Set<Id>();
		for (sObject anObject : (theObjects == null ? theOldObjects.values() : theObjects)) {
			Boolean anIsModified = false;
			if (theObjects == null || theOldObjects == null) {
				anIsModified = true;
			} else {
				for (String aField : theFieldsList) {
					if (anObject.get(aField) != theOldObjects.get(anObject.Id).get(aField)) {
						anIsModified = true;
						Object aParentId = theOldObjects.get(anObject.Id).get(aField);
						if (aField == theParentFild && aParentId != null) {
							aResult.add((Id) aParentId);
						}
					}
				}
			}
			Id aParentId = (Id) anObject.get(theParentFild);
			if (anIsModified && aParentId != null) {
				aResult.add((Id) anObject.get(theParentFild));
			}
		}

		return aResult;
	}

	/**
	  It retrieves all the record types from DB.
	  You can get record type Id by key "ObjectName:RecordTypeName".
	  For example TriggerUtils.recordTypes.get('Produkt__c:Basisprodukt').
	 */
	public static Map<String, ID> recordTypes {
		get {
			if (recordTypes == null) {
				recordTypes = new Map<String, Id>();
				for (RecordType aRecordType : [SELECT SObjectType, Id, DeveloperName FROM RecordType]) {
					recordTypes.put (aRecordType.SobjectType + ':' + aRecordType.DeveloperName, aRecordType.id);
				}
			}
			return recordTypes;
		}
		set;
	}

	/**
	 *	@description Get Id set of modified object by defined list of modified fields.
	 */
	public static Set<Id> getModifiedObjectIds(List<String> fieldsList, List<sObject> newObjects, Map<Id, sObject> oldObjectsMap) {
		Set<Id> theResult = new Set<Id>();
		if (newObjects != null) {
			for (sObject anObject : newObjects) {
				sObject oldObj = (oldObjectsMap != null) ? oldObjectsMap.get(anObject.Id) : null;
				if (oldObj == null) {
					theResult.add(anObject.Id);
				} else {
					for (String aField : fieldsList) {
						if (anObject.get(aField) != oldObj.get(aField)) {
							theResult.add(anObject.Id);
						}
					}
				}
			}
		} else if (oldObjectsMap != null) {
			theResult.addAll(oldObjectsMap.keySet());
		}

		return theResult;
	}

	/**
	 * It retrieves all the record types (ObjectName.DeveloperName)
	 */
	public static List<String> getDeveloperNameRecordTypes(String sObjType) {
		List<String> rTypes = new List<String>();
		for (RecordType aRecordType : [SELECT SobjectType, Id, DeveloperName FROM RecordType WHERE SObjectType = :sObjType]) {
			rTypes.add(aRecordType.SobjectType + '.' + aRecordType.DeveloperName);
		}
		return rTypes;
	}

	/**
	  Get object set of modified object by defined list of fields.
	  That means we can list of objects, were one or more fields where modified.
	 */
	public static Set<sObject> getModifiedObjects(List<String> theFieldsList, List<sObject> theObjects, Map<Id, sObject> theOldObjects) {
		Set<sObject> theResult = new Set<sObject>();
		if (theObjects != null) {
			for (sObject anObject : theObjects) {
				if (theOldObjects == null) {
					theResult.add(anObject);
				} else {
					sObject anOldObject = theOldObjects.get(anObject.Id);
					if (anOldObject == null) {
						theResult.add(anObject);
					} else {
						for (String aField : theFieldsList) {
							if (anObject.get(aField) != anOldObject.get(aField)) {
								theResult.add(anObject);
							}
						}
					}
				}
			}
		}

		return theResult;
	}

	/**
	 *	@description method is used to create parent to children Map using specified parent field name
	 */
	public static Map<Id, List<sObject>> getParentToChilrenMap(String parentField, Set<sObject> chilrend) {
		Map<Id, List<sObject>> parentToChilren = new Map<Id, List<sObject>>();

		for (sObject child : chilrend) {
			Id parentRecordId = (Id) child.get(parentField);
			if (parentToChilren.get(parentRecordId) == null) {
				parentToChilren.put(parentRecordId, new List<sObject>());
			}
			parentToChilren.get(parentRecordId).add(child);
		}

		return parentToChilren;
	}


	/**
	 * Method created to get relationship values i.e CustomObject__r.ACustomObject__r.BCustomField__c
	 */
	public static Object getSObjectValue(SObject source, String fieldName) {
		Object value = null;
		List<String> fields = new List<String>(fieldName.split('[.]'));

		if (fields.size() == 1) {
			return source.get(fieldName);
		} else {
			List<SObject> objects = new List<SObject>{
				source
			};
			Integer lastPos = fields.size();

			for (Integer i = 0; i < lastPos; i++) {
				if (i == lastPos - 1) {

					try {
						value = objects[i].get(fields[i]);
					} catch (Exception e) {
						value = null;
					}

				} else {
					objects.add(objects[i].getSObject(fields[i].trim()));
				}
			}
		}

		return value;
	}

	/*
	 * Key generator
	 **/
	public static String newGuid() {
		String kHexChars = '0123456789abcdef';

		String returnValue = '';
		Integer nextByte = 0;

		for (Integer i = 0; i < 16; i++) {

			if (i == 4 || i == 6 || i == 8 || i == 10)
				returnValue += '-';

			nextByte = (Math.round(Math.random() * 255) - 128) & 255;

			if (i == 6) {
				nextByte = nextByte & 15;
				nextByte = nextByte | (4 << 4);
			}

			if (i == 8) {
				nextByte = nextByte & 63;
				nextByte = nextByte | 128;
			}

			returnValue += getCharAtIndex(kHexChars, nextByte >> 4);
			returnValue += getCharAtIndex(kHexChars, nextByte & 15);
		}

		return returnValue;
	}

	private static String getCharAtIndex(String str, Integer index) {

		if (str == null) return null;

		if (str.length() <= 0) return str;

		if (index == str.length()) return null;

		return str.substring(index, index + 1);
	}


	/**
	 * Return RecordTypeId
	 * @type SObjectType
	 * @name String
	 */
	public static Id getRecordTypeIdByName(SObjectType type, String name) {
		return type
			.getDescribe()
			.getRecordTypeInfosByName()
			.get(name)
			.getRecordTypeId();
	}

	/**
	 * Return RecordTypeId
	 * @type SObjectType
	 * @name String
	 */
	public static Id getRecordTypeIdByDevName(String typeSO, String devName) {
		return [
			SELECT Id
			FROM RecordType
			WHERE SObjectType = :typeSO
			AND DeveloperName = :devName
		].Id;
	}

	/**
	 * Return a Map of RecordTypes (DeveloperName, Id)
	 * @typeSO SObjectType
	 */
	public static Map<String, Id> getRecordTypeInfosId(String typeSO) {
		Map<String, Id> infos = new Map<String, Id>();

		for (RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = :typeSO]) {
			infos.put(rt.DeveloperName, rt.Id);
		}

		return infos;
	}

	/**
	 * Return a Map of RecordTypes (Id, DeveloperName)
	 * @typeSO SObjectType
	 */
	public static Map<Id, String> getRecordTypeInfosName(String typeSO) {
		Map<Id, String> infos = new Map<Id, String>();

		for (RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = :typeSO]) {
			infos.put(rt.Id, rt.DeveloperName);
		}

		return infos;
	}

	/**
	 * Return translated label for RecordType
	 */
	public static String getRecordTypeLabel(String typeSO, String name) {
		return [
			SELECT toLabel(Name)
			FROM RecordType
			WHERE SObjectType = :typeSO
			AND Name = :name
		].Name;
	}

	/**
	 * Convert a list to a Map according to the field passed as param
	 * Return Map<Id, Object>
	 * @field SObjectField
	 * @record List<SObject> records
	 */
	public static Map<Id, SObject> listToMap(SObjectField field, List<SObject> records) {
		Map<Id, SObject> newMap = new Map<Id, SObject>();

		for (SObject o : records) {
			if (o.get(field) != null)
				newMap.put((Id) o.get(field), o);
		}

		return newMap;
	}

	/**
	 * Convert a list to a Map according to the field passed as param
	 * Return Map<Id, List<Object>>
	 * @field String (i.e: 'Name' or even relationships field 'Contact.Name'
	 * @record List<SObject> records
	 */
	public static Map<Id, List<SObject>> listToMapLists(String field, List<SObject> records) {
		Map<Id, List<SObject>> newMap = new Map<Id, List<SObject>>();

		for (SObject o : records) {
			Object value = getSObjectValue(o, field);
			if (value != null) {
				List<SObject> listObjects = newMap.get((Id) value);

				if (listObjects == null)
					newMap.put((Id) value, new List<SObject>{
						o
					}); else
					listObjects.add(o);
			}
		}

		return newMap;
	}


	/**
	 * Get any picks list value
	 * Return List<String>
	 * @field SObjectField
	 */
	public static List<String> getPicklist(SObjectField field) {

		List<String> values = new List<String>();
		for (Schema.PicklistEntry pl : field.getDescribe().getPicklistValues()) {
			values.add(pl.getLabel());
		}

		return values;
	}

	/**
	 * Get any picks list value and label
	 * Return Map<String, String>
	 * @field SObjectField
	 */
	public static Map<String, String> getPicklistEntries(SObjectField field) {
		Map<String, String> values = new  Map<String, String>();
		for (Schema.PicklistEntry pl : field.getDescribe().getPicklistValues()) {
			values.put(pl.getValue(), pl.getLabel());
		}

		return values;
	}

	/**
	 * Get picklist by RecordType
	 * Return Map<String, String>
	 * @field SObjectField
	 *
	 */
	public static Map<String, String> getPicklistByRecordType(SObjectField field, String recordTypeName) {
		String fieldName = field.getDescribe().getName();

		Map<String, String> translations = getPicklistTranslations(recordTypeName.split('[.]')[0], new Set<String>{
			fieldName
		});

		MetadataService.MetadataPort service = new MetadataService.MetadataPort();
		service.SessionHeader = new MetadataService.SessionHeader_element();
		service.SessionHeader.sessionId = getSessionIdPage();//MetadataLogin.getSessionId();

		Set<String> values = new Set<String>();

		MetadataService.RecordType recordType = (MetadataService.RecordType) service.readMetadata(
			'RecordType', new String[]{
				recordTypeName
			}
		).getRecords()[0];

		for (MetadataService.RecordTypePicklistValue rpk : recordType.picklistValues) {
			if (fieldName == rpk.picklist) {
				for (MetadataService.PicklistValue pk : rpk.values) {
					values.add(
						translations.get(EncodingUtil.urlDecode(pk.fullName, 'utf-8'))
					);
				}
			}
		}

		Map<String, String> valuesMap = new Map<String, String>();
		for (Schema.PicklistEntry pl : field.getDescribe().getPicklistValues()) {
			if (values.contains(pl.getLabel()))
				valuesMap.put(pl.getValue(), pl.getLabel());
		}

		return valuesMap;
	}


	/**
	 * Get picklists translations by Object and Field
	 * Return Map<MasterLabel, Translation>
	 * @sObjType String
	 * @field String
	 *
	 */
	public static Map<String, String> getPicklistTranslations(String sObjType, Set<String> fields) {

		MetadataService.MetadataPort service = new MetadataService.MetadataPort();
		service.SessionHeader = new MetadataService.SessionHeader_element();
		service.SessionHeader.sessionId = getSessionIdPage();//MetadataLogin.getSessionId();

		Map<String, String> values = new Map<String, String>();

		MetadataService.CustomObjectTranslation customObj = (MetadataService.CustomObjectTranslation) service.readMetadata(
			'CustomObjectTranslation', new String[]{
				sObjType + '-' + UserInfo.getLanguage()
			}
		).getRecords()[0];

		for (MetadataService.CustomFieldTranslation cft : customObj.fields) {
			if (fields.contains(cft.name)) {
				for (MetadataService.PicklistValueTranslation pkt : cft.picklistValues) {
					values.put(EncodingUtil.urlDecode(pkt.masterLabel, 'utf-8'), EncodingUtil.urlDecode(pkt.translation, 'utf-8'));
				}
			}
		}

		return values;
	}

	/**
	 * Get picklists by Object and Field
	 * Return List<String>
	 * @sObjType String
	 * @fields List<String>
	 *
	 */
	public static Map<String, Map<String, List<String>>> getPicklistGroupedByRecordType(String sObjType, List<String> fields) {

		if (sObjType == null || fields == null || fields.isEmpty()) return null;

		Map<String, String> translations = getPicklistTranslations(sObjType, new Set<String>(fields));
		Map<String, Map<String, List<String>>> groupPicklist = new Map<String, Map<String, List<String>>>();

		for (String f : fields) {
			groupPicklist.put(f, new Map<String, List<String>>());
		}

		MetadataService.MetadataPort service = new MetadataService.MetadataPort();
		service.SessionHeader = new MetadataService.SessionHeader_element();
		service.SessionHeader.sessionId = getSessionIdPage();//MetadataLogin.getSessionId();

		List<MetadataService.RecordType> rTypes = (List<MetadataService.RecordType>) service.readMetadata(
			'RecordType', getDeveloperNameRecordTypes(sObjType)
		).getRecords();

		for (MetadataService.RecordType rt : rTypes) {
			String rtLabel = getRecordTypeLabel(sObjType, rt.label);

			for (MetadataService.RecordTypePicklistValue rpk : rt.picklistValues) {

				if (groupPicklist.containsKey(rpk.picklist)) {
					for (MetadataService.PicklistValue pk : rpk.values) {
						Map<String, List<String>> values = groupPicklist.get(rpk.picklist);

						if (values.containsKey(rtLabel)) {
							values.get(rtLabel).add(
								translations.get(EncodingUtil.urlDecode(pk.fullName, 'utf-8'))
							);
						} else {
							if (pk.fullName != 'None')
								values.put(
									rtLabel,
									new List<String>{
										translations.get(EncodingUtil.urlDecode(pk.fullName, 'utf-8'))
									}
								);
						}

					}
				}

			}
		}

		return groupPicklist;
	}

	public static String getSessionIdPage() {
		String sessionId = Page.SessionId.getContent().toString();
		return sessionId;
	}

	public static String formatDate(Date d, String format) {
		return DateTime.newInstance(d.year(), d.month(), d.day()).format(format);
	}

}