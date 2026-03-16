public with sharing class LookupController {

    @AuraEnabled
    public static List<sObject> searchLookup(String query, String type, Id filterById) {

        String name = '%' + query + '%';

        if(type == 'User'){

            String RecordTypeName = 'Internal Contact';
            String baseQuery = 'SELECT Id, Name, Account.Name, LocalCurrency__c, AccountId FROM Contact WHERE name LIKE :name and RecordType.Name = :RecordTypeName ';

            if(filterById != null){
                baseQuery += ' and AccountId = :filterById ';
            }

            baseQuery += ' ORDER BY Name ASC LIMIT 100';

            return Database.query(baseQuery);

        }

        if(type == 'Account'){
            return [SELECT id, name FROM Account WHERE name LIKE :name or AccountNameShort__c LIKE :name or AccountNr__c LIKE :name ORDER BY Name ASC LIMIT 100];
        }

        if(type == 'Internal Account'){
            return [SELECT id, name
                    FROM Account
                    WHERE ( name LIKE :name or AccountNameShort__c LIKE :name)
                    AND RecordType.Name = 'Internal Account'
                    ORDER BY Name ASC LIMIT 100];
        }

        if(type == 'Segment'){
            return [SELECT id, name FROM Segment__c WHERE name LIKE :name ORDER BY Name ASC LIMIT 100];
        }

        if(type == 'Project'){

            String ProjectStatus = 'Open';
            String ProjectSubType = 'Absence';

            String baseQuery = 'SELECT Id, Name, ProjectNr__c, ProjectPartner__r.Id, ProjectPartner__r.Name, ProjectCurrency__c FROM Project__c WHERE (name LIKE :name or ProjectNameInternal__c LIKE :name or ProjectNr__c LIKE :name or Id = :query) and ProjectStatus__c = :ProjectStatus and ProjectSubType__c != :ProjectSubType';

            if(filterById != null){
                baseQuery += ' and ContractPartner__c = :filterById ';
            }

            baseQuery += ' ORDER BY Name ASC LIMIT 100 ';

            return Database.query(baseQuery);

        }

        if(type == 'Expense Project' || type == 'all project'){

            String ProjectStatus = 'Open';
            String OrProjectStatus = 'Partially open (w/o Time Entry)';
            String ProjectSubType = 'Absence';

            String baseQuery = 'SELECT Id, Name, ProjectNr__c, ProjectPartner__r.Id, ProjectPartner__r.Name, ProjectCurrency__c FROM Project__c WHERE (name LIKE :name or ProjectNameInternal__c LIKE :name or ProjectNr__c LIKE :name or Id = :query) and (ProjectStatus__c = :ProjectStatus or ProjectStatus__c = :OrProjectStatus) and ProjectSubType__c != :ProjectSubType';

            if(filterById != null){
                baseQuery += ' and ContractPartner__c = :filterById ';
            }

            baseQuery += ' ORDER BY Name ASC LIMIT 100 ';

            return Database.query(baseQuery);

        }

        if(type == 'open and closed project'){

            String NotProjectSubType = 'Absence';
            String baseQuery = 'SELECT Id, Name, ProjectNr__c, ProjectPartner__r.Id, ProjectPartner__r.Name, ProjectCurrency__c FROM Project__c WHERE (name LIKE :name or ProjectNameInternal__c LIKE :name or ProjectNr__c LIKE :name or Id = :query) and ProjectSubType__c != :NotProjectSubType';

            if(filterById != null){
                baseQuery += ' and ContractPartner__c = :filterById ';
            }

            baseQuery += ' ORDER BY Name ASC LIMIT 100 ';

            return Database.query(baseQuery);

        }

        if(type == 'Package'){

            String baseQuery = 'SELECT Id, PackageNr__c, Name, ProjectName__c, ProjectName__r.Name, ProjectName__r.ProjectNr__c, ProjectName__r.ProjectPartner__r.Id, ProjectName__r.ProjectCurrency__c, ProjectName__r.ProjectPartner__r.Name, PackageSortNr__c FROM Package__c WHERE (name LIKE :name or PackageNr__c LIKE :name or Id = :query)';

            if(filterById != null){
                baseQuery += ' and ProjectName__c = :filterById ';
            }

            baseQuery += ' ORDER BY PackageSortNr__c, Name ASC LIMIT 100';

            return Database.query(baseQuery);

        }

        if(type == 'Work Package'){

            String packageStatus = 'Open';
            String RecordTypeName = 'Time';
            String SubType = 'WorkTime';
            String OrSubType = 'Manufaktur';
            String NotProjectSubType = 'Absence';
            String baseQuery = 'SELECT Id, PackageSubType__c, PackageNr__c, Name, ProjectName__c, ProjectName__r.Name, ProjectName__r.ProjectNr__c, ProjectName__r.ProjectPartner__r.Id, ProjectName__r.ProjectCurrency__c, ProjectName__r.ProjectPartner__r.Name, PackageSortNr__c FROM Package__c WHERE (name LIKE :name or PackageNr__c LIKE :name or Id = :query) and PackageStatus__c = :packageStatus and RecordType.Name = :RecordTypeName and (PackageSubType__c = :SubType or PackageSubType__c = :OrSubType)  and ProjectName__r.ProjectSubType__c != :NotProjectSubType';

            if(filterById != null){
                baseQuery += ' and ProjectName__c = :filterById ';
            }

            baseQuery += ' ORDER BY PackageSortNr__c, Name ASC LIMIT 100';

            return Database.query(baseQuery);

        }

        if(type == 'Travel Package'){

            String packageStatus = 'Open';
            String RecordTypeName = 'Time';
            String SubType = 'TravelTime';
            String NotProjectSubType = 'Absence';
            String baseQuery = 'SELECT Id, Name, PackageNr__c, ProjectName__c, ProjectName__r.Name, ProjectName__r.ProjectNr__c, ProjectName__r.ProjectPartner__r.Id, ProjectName__r.ProjectCurrency__c, ProjectName__r.ProjectPartner__r.Name, PackageSortNr__c FROM Package__c WHERE (name LIKE :name or PackageNr__c LIKE :name or Id = :query) and PackageStatus__c = :packageStatus and RecordType.Name = :RecordTypeName and PackageSubType__c = :SubType  and ProjectName__r.ProjectSubType__c != :NotProjectSubType';

            if(filterById != null){
                baseQuery += ' and ProjectName__c = :filterById ';
            }

            baseQuery += ' ORDER BY PackageSortNr__c, Name ASC LIMIT 100';

            return Database.query(baseQuery);

        }

        if(type == 'Expense Package'){

            String packageStatus = 'Open';
            String RecordTypeName = 'Expense';
            String baseQuery = 'SELECT Id, Name, PackageNr__c, ProjectName__c, ProjectName__r.Name, ProjectName__r.ProjectNr__c, ProjectName__r.ProjectPartner__r.Id, ProjectName__r.ProjectCurrency__c, ProjectName__r.ProjectPartner__r.Name, PackageSortNr__c FROM Package__c WHERE (name LIKE :name or PackageNr__c LIKE :name or Id = :query) and PackageStatus__c = :packageStatus and RecordType.Name = :RecordTypeName ';

            if(filterById != null){
                baseQuery += ' and ProjectName__c = :filterById ';
            }

            baseQuery += ' ORDER BY PackageSortNr__c, Name ASC LIMIT 100';

            return Database.query(baseQuery);

        }

        if(type == 'Internal Package'){

            String packageStatus = 'Open';
            String RecordTypeName = 'Time';
            String SubType = 'WorkTime';
            String NotAbacusTimeType = '200';
            String ProjectSubType = 'Absence';
            String baseQuery = 'SELECT Id, Name, PackageNr__c, ProjectName__c, ProjectName__r.Name, ProjectName__r.ProjectNr__c, ProjectName__r.ContractPartner__c, ProjectName__r.ProjectCurrency__c, ProjectName__r.ContractPartner__r.Name, PackageSortNr__c FROM Package__c WHERE (name LIKE :name or PackageNr__c LIKE :name) and PackageStatus__c = :packageStatus and RecordType.Name = :RecordTypeName and AbacusTimeType__c <> :NotAbacusTimeType and PackageSubType__c = :SubType and ProjectName__r.ProjectSubType__c = :ProjectSubType';

            if(filterById != null){
                baseQuery += ' and ProjectName__c = :filterById ';
            }

            baseQuery += ' ORDER BY PackageSortNr__c, Name ASC LIMIT 100';

            return Database.query(baseQuery);

        }

        // used on the absence tracker tab
        if(type == 'Internal Project'){

            return [SELECT id, ProjectNr__c, name FROM Project__c
                    WHERE (name LIKE :name or ProjectNr__c LIKE :name or Id = :query)
                    and RecordType.Name = 'Internal'
                    and ProjectStatus__c = 'Open'
                    ORDER BY Name ASC LIMIT 100];

        }

        // used on the expense tracker tab
        if(type == 'Credit Card'){

            return [SELECT Id, Name, CreditCard__c
                    FROM Inventory__c
                    WHERE (name LIKE :name or CreditCard__c LIKE :name)
                    AND RecordType.Name = 'Credit Card' 
                    AND ValAvailableInApp__c = true
                    limit 100];

        }

        // used on the expense tracker tab
        if(type == 'Car'){

            return [SELECT Id, Name, Car__c
                    FROM Inventory__c
                    WHERE (name LIKE :name or Car__c LIKE :name)
                    AND RecordType.Name = 'Car' 
                    AND ValAvailableInApp__c = true
                    limit 100];

        }

        return new List<sObject>();

    }

}