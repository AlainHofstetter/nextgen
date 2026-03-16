public with sharing class ILVPosService {

  private static IILVPosService service() {
    return (IILVPosService) Application.Service.newInstance(IILVPosService.class);
  }

  public static ILVCreation get(Id projectId, String dateFrom, String dateTo) {
    return service().get(projectId, dateFrom, dateTo);
  }

  public static void save(Invoice__c draft, List<ILVPos__c> positions) {
    service().save(draft, positions);
  }

}