public interface IILVPosService {

  ILVCreation get(Id projectId, String dateFrom, String dateTo);

  void save(Invoice__c draft, List<ILVPos__c> positions);

}