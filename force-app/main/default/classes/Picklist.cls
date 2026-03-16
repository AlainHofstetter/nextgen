public without sharing class Picklist {

    /**
     * Get a picklist value regardless of the user language
     */
    public static String get(SObjectField field, String value) {
        DescribeFieldResult result = field.getDescribe();

        for(PicklistEntry pe: result.getPicklistValues())
            if (value == pe.getLabel())
                return pe.getValue();

        return null;
    }
}