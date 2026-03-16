public with sharing class ILVPosServiceImpl
  implements IILVPosService {

  public ILVCreation get(Id projectId, String dateFrom, String dateTo) {
    return PackageSelector.newInstance().selectILVInfo(projectId, dateFrom, dateTo);
  }

  public void save(Invoice__c draft, List<ILVPos__c> positions) {
    fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();

    IInvoice invoiceDomain = Invoice.newInstance(new List<Invoice__c> {draft});
    invoiceDomain.save(uow, Invoice.RECORD_TYPE_ILV);

    IILVPos ipDomain = ILVPos.newInstance(positions);
    ipDomain.save(uow, draft);

    uow.commitWork();

  }
}