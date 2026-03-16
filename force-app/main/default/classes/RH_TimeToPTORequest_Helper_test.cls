@IsTest
public class RH_TimeToPTORequest_Helper_test {
    /*
    @isTest(SeeAllData=true)
    static void test_InsertAbsense() {
        User testuser = [SELECT Id FROM User WHERE Username like '%antonio.farati%'];
        System.runAs(testuser) {
            Project__c project = [SELECT Id FROM Project__c where Name = 'Abwesenheiten Antonio Farati' limit 1];
            Package__c service = [SELECT Id FROM Package__c where Name = 'Ferien' AND ProjectName__c = :project.Id];

            List<Time__c> timeentries = new List<Time__c>();
            timeentries.add(new Time__c(DateFrom__c = Date.valueOF('2014-06-09'),
                                        DateUntil__c = Date.valueOf('2014-06-09'),
                                        DurationHhMmN__c = 8,
                                        ProjectName__c = project.Id,
                                        Package__c = service.Id));
            timeentries.add(new Time__c(DateFrom__c = Date.valueOF('2014-06-10'),
                                        DateUntil__c = Date.valueOf('2014-06-10'),
                                        DurationHhMmN__c = 8,
                                        ProjectName__c = project.Id,
                                        Package__c = service.Id));
            timeentries.add(new Time__c(DateFrom__c = Date.valueOF('2014-06-11'),
                                        DateUntil__c = Date.valueOf('2014-06-11'),
                                        DurationHhMmN__c = 8,
                                        ProjectName__c = project.Id,
                                        Package__c = service.Id));
            Test.startTest();
            insert timeentries;
            Test.stopTest();

            List<ResourceHeroApp__Resource_Forecast__c> rfs = [SELECT Id, Name, ResourceHeroApp__PTO_Request__c, ResourceHeroApp__Forecast__c, ResourceHeroApp__Actual__c, ResourceHeroApp__Resource_Assignment__c, CreatedDate
                                                                FROM ResourceHeroApp__Resource_Forecast__c
                                                                WHERE ResourceHeroApp__ForecastDate__c >= :Date.valueOf('2014-06-08')
                                                                    AND ResourceHeroApp__ForecastDate__c <= :Date.valueOf('2014-06-12')
                                                                    AND ResourceHeroApp__PTO_Request__c != null];

            system.assertEquals(3, rfs.size());
        }
    }

    @isTest(SeeAllData=true)
    static void test_UpdateAbsense() {
        User testuser = [SELECT Id FROM User WHERE Username like '%antonio.farati%'];
        System.runAs(testuser) {
            Project__c project = [SELECT Id FROM Project__c where Name = 'Abwesenheiten Antonio Farati' limit 1];
            Package__c service = [SELECT Id FROM Package__c where Name = 'Ferien' AND ProjectName__c = :project.Id];

            List<Time__c> timeentries = new List<Time__c>();
            timeentries.add(new Time__c(DateFrom__c = Date.valueOF('2014-06-09'),
                                        DateUntil__c = Date.valueOf('2014-06-09'),
                                        DurationHhMmN__c = 8,
                                        ProjectName__c = project.Id,
                                        Package__c = service.Id));
            timeentries.add(new Time__c(DateFrom__c = Date.valueOF('2014-06-10'),
                                        DateUntil__c = Date.valueOf('2014-06-10'),
                                        DurationHhMmN__c = 8,
                                        ProjectName__c = project.Id,
                                        Package__c = service.Id));
            timeentries.add(new Time__c(DateFrom__c = Date.valueOF('2014-06-11'),
                                        DateUntil__c = Date.valueOf('2014-06-11'),
                                        DurationHhMmN__c = 8,
                                        ProjectName__c = project.Id,
                                        Package__c = service.Id));
            
            insert timeentries;
            Test.startTest();

            timeentries[1].DurationHhMmN__c = 4;
            update timeentries[1];
            Test.stopTest();

            List<ResourceHeroApp__Resource_Forecast__c> rfs = [SELECT Id, Name, ResourceHeroApp__PTO_Request__c, ResourceHeroApp__Forecast__c, ResourceHeroApp__Actual__c, ResourceHeroApp__Resource_Assignment__c, CreatedDate
                                                                FROM ResourceHeroApp__Resource_Forecast__c
                                                                WHERE ResourceHeroApp__ForecastDate__c = :Date.valueOf('2014-06-10')
                                                                    AND ResourceHeroApp__PTO_Request__c != null];

            system.assertEquals(1, rfs.size());
            system.assertEquals(4, rfs[0].ResourceHeroApp__Forecast__c);
        }
    }


    @isTest(SeeAllData=true)
    static void test_DeleteAbsense() {
        User testuser = [SELECT Id FROM User WHERE Username like '%antonio.farati%'];
        System.runAs(testuser) {
            Project__c project = [SELECT Id FROM Project__c where Name = 'Abwesenheiten Antonio Farati' limit 1];
            Package__c service = [SELECT Id FROM Package__c where Name = 'Ferien' AND ProjectName__c = :project.Id];

            List<Time__c> timeentries = new List<Time__c>();
            timeentries.add(new Time__c(DateFrom__c = Date.valueOF('2014-06-09'),
                                        DateUntil__c = Date.valueOf('2014-06-09'),
                                        DurationHhMmN__c = 8,
                                        ProjectName__c = project.Id,
                                        Package__c = service.Id));
            timeentries.add(new Time__c(DateFrom__c = Date.valueOF('2014-06-10'),
                                        DateUntil__c = Date.valueOf('2014-06-10'),
                                        DurationHhMmN__c = 8,
                                        ProjectName__c = project.Id,
                                        Package__c = service.Id));
            timeentries.add(new Time__c(DateFrom__c = Date.valueOF('2014-06-11'),
                                        DateUntil__c = Date.valueOf('2014-06-11'),
                                        DurationHhMmN__c = 8,
                                        ProjectName__c = project.Id,
                                        Package__c = service.Id));
            insert timeentries;
            Test.startTest();
            delete timeentries[1];
            Test.stopTest();

            List<ResourceHeroApp__Resource_Forecast__c> rfs = [SELECT Id, Name, ResourceHeroApp__PTO_Request__c, ResourceHeroApp__Forecast__c, ResourceHeroApp__Actual__c, ResourceHeroApp__Resource_Assignment__c, CreatedDate
                                                                FROM ResourceHeroApp__Resource_Forecast__c
                                                                WHERE ResourceHeroApp__ForecastDate__c = :Date.valueOf('2014-06-10')
                                                                    AND ResourceHeroApp__PTO_Request__c != null];

            system.assertEquals(0, rfs.size());
        }
    }
*/
}