public with sharing class ProjectStructureBean {

  @AuraEnabled
  public Project__c project;

  @AuraEnabled
  public Invoice__c invoice;

  @AuraEnabled
  public List<PackageBean> packages;

  public ProjectStructureBean(Invoice__c invoice, List<Package__c> packages) {
    this.invoice = invoice;
    this.buildStructure(packages);
  }

  private void buildStructure(List<Package__c> packages) {

    this.project
      = (packages != null && !packages.isEmpty())
      ? packages[0].ProjectName__r
      : null;

    this.packages = new List<PackageBean>();
    PackageBean currentGroup = null;
    for (Package__c pck: packages) {
      if (pck.PackageType__c == PackageDomain.TYPE_GROUP) {
        currentGroup = new PackageBean(pck);
        this.packages.add(currentGroup);
      } else {
        if (currentGroup != null && pck.PackageSuperior__c == currentGroup.pck.Id)
          this.packages.add(new PackageBean(pck, currentGroup));
        else
          this.packages.add(new PackageBean(pck, null));
      }
    }

  }

  public static Set<String> projectPackageFields = new Set<String> {
    'Id',
    'Name',
    'PackageType__c',
    'PackageSortNr__c',
    'PackageNr__c',
    'PackageSuperior__c',
    'ShowPosition__c',
    'ShowPositionAmount__c',
    'ShowInvoiceText__c',
    'PackageStatus__c',
    'PackageResponsibleBusiness__r.Name',
    'ExpenseDescription__c',
    'InvoicePOSTotalTime__c',
    'InvoicePOSTotalExpense__c',
    'InvoicePOSTotalSupplierCosts__c',
    'ServicesTotalAmount__c',
    'BudgetAssignPackage__c',
    'PackageBillingPositionText__c',
    'ProjectManagementAllowancePackage__c',
    'ExcludeFromExpenseAllowance__c',
    'ExpenseBillingType__c',
    'ExcludeFromProjectMgmtAllowance__c',
    'SupplierCostsGroup__c',
    'ExpenseAllowancePackage__c',
    'RecordType.Name',
    'PackageSubType__c',
    'ProjectName__r.Id',
    'ProjectName__r.Name',
    'ProjectName__r.ProjectNr__c',
    'ProjectName__r.ProjectCostCenter__r.Name',
    'ProjectName__r.ProjectType__c',
    'ProjectName__r.ProjectSubType__c',
    'ProjectName__r.ProjectCurrency__c',
    'ProjectName__r.BillingNotes__c',
    'ProjectName__r.ProjectRateHour__c',
    'ProjectName__r.ProjectManagementBillingType__c',
    'ProjectName__r.ExpenseBillingType__c',
    'ProjectName__r.DefaultInvoiceTitle__c',
    'ProjectName__r.InvoiceReceiver__r.Name',
    'ProjectName__r.VATPercent__c',
    'ProjectName__r.InvoiceReceiver__r.Name',
    'ProjectName__r.ProjectManagementAllowancePercent__c',
    'ProjectName__r.ExpenseAllowancePercent__c',
    'ProjectName__r.ProjectManagementAllowancePercent__c',
    'ProjectName__r.ExpenseAllowancePercent__c',
    'ProjectName__r.DefaultInvoiceDescription__c'
  };

  public static Set<String> timeFields = new Set<String> {
    'DateFrom__c',
    'ServiceTotalTime__c'
  };

  public static Set<String> expenseFields = new Set<String> {
    'ExpenseDate__c',
    'ServiceExpenseNet__c'
  };

  public static Set<String> supplierCostsFields = new Set<String> {
    'SupplierCostsDate__c',
    'ServiceSupplierCostsNetPM__c'
  };

  public static Set<String> invoicePosFields = new Set<String> {
    'InvoiceName__c',
    'InvoicePositionSuperior__c',
    'InvoicePositionAmount__c',
    'InvoicePositionText__c',
    'ShowPosition__c',
    'ShowPositionAmount__c',
    'ShowInvoiceText__c'
  };
}