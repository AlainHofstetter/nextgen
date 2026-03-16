public with sharing class InvoiceServiceImpl
        implements IInvoiceService {

    public Invoice__c get(Id recordId) {
        List<SObject> invs = InvoiceSelector.newInstance().selectSObjectsById(new Set<Id>{
                recordId
        });
        return !invs.isEmpty() ? (Invoice__c) invs[0] : null;
    }

    public ProjectStructureBean getProjectStructure(Id projectId, String dateFrom, String dateTo) {
        return PackageSelector.newInstance().selectProjectStructure(projectId, dateFrom, dateTo);
    }

    public void save(Invoice__c draft, List<Package__c> packages, List<InvoicePos__c> positions) {
        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();

        IPackageDomain pckDomain = PackageDomain.newInstance(packages);
        pckDomain.save(uow);

        IInvoice invoiceDomain = Invoice.newInstance(new List<Invoice__c>{
                draft
        });
        invoiceDomain.save(uow, Invoice.RECORD_TYPE_INVOICE);

        IInvoicePosition invoicePDomain = InvoicePosition.newInstance(positions);
        invoicePDomain.save(uow, draft);

        uow.commitWork();

        fflib_ISObjectUnitOfWork updatePositions = Application.UnitOfWork.newInstance();
        invoicePDomain.findSuperiors(updatePositions, packages);
        updatePositions.commitWork();
    }

    public Invoice__c cancel(Id invoiceId) {
        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();

        List<Invoice__c> invoices = InvoiceSelector.newInstance().selectSObjectsById(new Set<Id>{
                invoiceId
        });
        IInvoice invoiceDomain = Invoice.newInstance(invoices);
        List<Invoice__c> cancelledInvoices = invoiceDomain.cancel(uow);

        return cancelledInvoices[0];
    }

}