public with sharing class ILVCreation {

  @AuraEnabled
  public Project__c project;

  @AuraEnabled
  public Invoice__c invoice;

  @AuraEnabled
  public List<PackageILVCreation> packages;

  @AuraEnabled
  public List<CostCenterILVCreation> leadingCC;

  @AuraEnabled
  public List<List<CostCenterILVCreation>> receivingCC;

  private Id leadingId;
  private Map<Id, String> costCenterNames;
  private DateRange dates;

  public ILVCreation(Invoice__c invoice, List<Package__c> packages, String dateFrom, String dateTo) {
    this.invoice = invoice;
    this.setDates(dateFrom, dateTo);
    this.setProject(packages);
    this.extractCostCenters(packages);
    this.buildILVData(packages);
  }

  private void setDates(String dateFrom, String dateTo) {
    if(invoice != null && dateFrom == null && dateTo == null) {
      this.dates = new DateRange(
          Utils.formatDate(invoice.PeriodFrom__c, 'yyyy-MM-dd'),
          Utils.formatDate(invoice.PeriodUntil__c, 'yyyy-MM-dd')
      );
    } else {
      this.dates = new DateRange(dateFrom, dateTo);
    }
  }

  private void setProject(List<Package__c> packages) {
    project
      = (packages != null && !packages.isEmpty())
      ? packages[0].ProjectName__r
      : null;
  }

  private void extractCostCenters(List<Package__c> packages) {
    leadingId = project.ProjectCostCenter__c;
    costCenterNames = new Map<Id, String>();
    costCenterNames.put(leadingId, project.ProjectCostCenter__r.Name);

    for (Package__c pck : packages) {
      for (Time__c t : pck.Time__r) {

        if (t.TimeTrackerCostCenter__c != null && t.TimeTrackerCostCenter__c != leadingId) {
          costCenterNames.put(t.TimeTrackerCostCenter__c, t.TimeTrackerCostCenter__r.Name);
        }

      }
    }

  }

  public void buildILVData(List<Package__c> packages) {
    buildPackages(packages);
    buildCostCenters(packages);
  }

  public void buildPackages(List<Package__c> packages) {

    this.packages = new List<PackageILVCreation>();
    PackageILVCreation currentGroup = null;

    for (Package__c pck: packages) {
      if (pck.PackageType__c == PackageDomain.TYPE_GROUP) {
        currentGroup = new PackageILVCreation(pck);
        this.packages.add(currentGroup);
      } else {
        if (currentGroup != null && pck.PackageSuperior__c == currentGroup.pck.Id)
          this.packages.add(new PackageILVCreation(pck, currentGroup, dates));
        else
          this.packages.add(new PackageILVCreation(pck, null, dates));
      }
    }

  }

  public void buildCostCenters(List<Package__c> packages) {
    leadingCC = new List<CostCenterILVCreation>();
    receivingCC = new List<List<CostCenterILVCreation>>();

    for (Id i: costCenterNames.keySet()) {
      List<CostCenterILVCreation> currentCC = new List<CostCenterILVCreation>();
      CostCenterILVCreation currentGroup = null;
      Boolean isLeadingCC = (i == leadingId);

      for (Package__c pck: packages) {
        if (pck.PackageType__c == PackageDomain.TYPE_GROUP) {
          currentGroup = new CostCenterILVCreation(
              i,
              costCenterNames.get(i),
              pck,
              invoice,
              isLeadingCC
          );
          currentCC.add(currentGroup);
        } else {
          if (currentGroup != null && pck.PackageSuperior__c == currentGroup.pck.Id)
            currentCC.add(new CostCenterILVCreation(i, costCenterNames.get(i), pck,
                        invoice, currentGroup, isLeadingCC, dates));
          else
            currentCC.add(new CostCenterILVCreation(i, costCenterNames.get(i), pck,
                        invoice, null, isLeadingCC, dates));
        }
      }

      if (isLeadingCC)
        leadingCC.addAll(currentCC);
      else
        receivingCC.add(currentCC);

    }

  }

  public static Set<String> projectPackageFields = new Set<String> {
    'Name',
    'PackageType__c',
    'PackageSortNr__c',
    'PackageSubType__c',
    'PackageSuperior__c',
    'InvoicePOSTotalTime__c',
    'InvoicePOSTotalExpense__c',
    'InvoicePOSTotalSupplierCosts__c',
    'ServicesTotalAmount__c',
    'BudgetAssignPackage__c',
    'PackageBillingPositionText__c',
    'ProjectCostCenter__c',
    'ProjectName__r.Name',
    'ProjectName__r.ProjectCostCenter__c',
    'ProjectName__r.ProjectCostCenter__r.Name',
    'ProjectName__r.ProjectCurrency__c',
    'ProjectName__r.ProjectRateHour__c',
    'ProjectName__r.ExpenseBillingType__c',
    'ProjectName__r.ProjectManagementBillingType__c',
    'ProjectName__r.InvoiceReceiver__c',
    'ProjectName__r.ProjectNr__c',
    'ProjectName__r.VATPercent__c',
    'ProjectName__r.InvoiceReceiver__r.Name',
    'ProjectName__r.ProjectManagementAllowancePercent__c',
    'ProjectName__r.ExpenseAllowancePercent__c'
  };

  public static Set<String> timeFields = new Set<String> {
    'DateFrom__c',
    'ServiceTotalTime__c',
    'TimeTrackerCostCenter__c',
    'TimeTrackerCostCenter__r.Name'
  };

  public static Set<String> expenseFields = new Set<String> {
    'ExpenseDate__c',
    'ServiceExpenseNet__c',
    'ExpensetrackerCostCenter__c'
  };

  public static Set<String> supplierCostsFields = new Set<String> {
    'SupplierCostsDate__c',
    'ServiceSupplierCostsNetPM__c',
    'ProjectCostCenter__c'
  };

  public static Set<String> invoicePosFields = new Set<String> {
    'InvoicePositionSuperior__c',
    'InvoicePositionAmount__c',
    'InvoiceName__c',
    'InvoiceName__r.FinanceDate__c'
  };

  public static Set<String> ilvPosFields = new Set<String> {
    'CostCenterILVReceiver__c',
    'ILVPositionAmount__c',
    'ILVType__c',
    'PackageSubType__c',
    'InvoiceName__c',
    'InvoiceName__r.InvoiceStatus__c'
  };

}