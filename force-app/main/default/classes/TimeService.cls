public with sharing class TimeService {

  private static ITimeService service() {
    return (ITimeService) Application.Service.newInstance(ITimeService.class);
  }

  public static void save(List<Time__c> times) {
    service().save(times);
  }

}