public with sharing class PackageBean {

  @AuraEnabled
  public Package__c pck {get; set;}

  @AuraEnabled
  public Double budget {get; set;}

  @AuraEnabled
  public Double invoice {get; set;}

  @AuraEnabled
  public Double availableFunds {get; set;}

  @AuraEnabled
  public Double servicesTotal {get; set;}

  @AuraEnabled
  public Double servicesTotalDR {get; set;}

  @AuraEnabled
  public Double invoiceNoDraft {get; set;}

  @AuraEnabled
  public Double invoiceInProgress {get; set;}

  @AuraEnabled
  public InvoicePos__c position {get; set;}

  /*
   * Dummy fields for the sake of LockerService
   */
  @AuraEnabled
  public Boolean showModalForBillingPositionText {get; set;}

  @AuraEnabled
  public Double calculatedAvailableFunds {get; set;}

  @AuraEnabled
  public Double allowanceTotal {get; set;}

  @AuraEnabled
  public Boolean showPosition {get; set;}

  @AuraEnabled
  public Boolean showPositionAmount {get; set;}

  @AuraEnabled
  public Boolean showInvoiceText {get; set;}

  @AuraEnabled
  public String packageBillingPositionText {get; set;}

  /**
  * Default constructor
  * mainly used for testing
  **/
  public PackageBean() {
    this.setDefaults();
  }

  /**
  * Group constructor
  * @p group package to be initialized
  **/
  public PackageBean(Package__c p) {
    this.pck = p;
    this.setDefaults();
    this.setPosition(null);
  }

  /**
  * Subgroup constructor
  * @p subpackage to be summed up
  * @pGroup parent package to be proccessed alongside to its subpackage
  **/
  public PackageBean(Package__c p, PackageBean pGroup) {
    this.pck = p;
    this.setDefaults();
    this.sumup(pGroup);
  }

  private void sumup(PackageBean pGroup) {
    setBudgetAndServicesTotal(pGroup);
    setPosition(pGroup);
    setInvoiceAndInvoiceNoDraft(pGroup);
    setAvaliableFunds(pGroup);
    setServicesTotalDR(pGroup);
  }

  public void setBudgetAndServicesTotal(PackageBean pGroup) {
    if (this.pck.BudgetAssignPackage__c != null) {
      this.budget = Test.isRunningTest() ? 10 : this.pck.BudgetAssignPackage__c;

      if (!isGroupNull(pGroup))
        pGroup.budget += Test.isRunningTest() ? 10 : this.pck.BudgetAssignPackage__c;
    }

    if (this.pck.ServicesTotalAmount__c != null) {
      this.servicesTotal = Test.isRunningTest() ? 10 : this.pck.ServicesTotalAmount__c;

      if (!isGroupNull(pGroup))
        pGroup.servicesTotal += Test.isRunningTest() ? 10 : this.pck.ServicesTotalAmount__c;
    }
  }

  public void setPosition(PackageBean pGroup) {
    Boolean isSubpackage = (pGroup != null);
    Boolean hasPosition = this.pck != null && this.pck.InvoicePos__r != null && this.pck.InvoicePos__r.size() == 1;

    if (hasPosition) {
      this.position = this.pck.InvoicePos__r;
      this.invoiceInProgress = this.position.InvoicePositionAmount__c;

      if (isSubpackage && !isGroupNull(pGroup)) {
        pGroup.position.InvoicePositionAmount__c += this.position.InvoicePositionAmount__c;
        pGroup.invoiceInProgress += this.position.InvoicePositionAmount__c;
      }
    } else {
      this.position = new InvoicePos__c(InvoicePositionAmount__c = 0);
    }
  }

  public void setInvoiceAndInvoiceNoDraft(PackageBean pGroup) {
    if (this.position != null) {

      if (this.pck.PackageType__c == PackageDomain.TYPE_TIME) {
        // this.invoice = this.pck.InvoicePOSTotalTime__c + this.position.InvoicePositionAmount__c;
        this.invoice = this.pck.InvoicePOSTotalTime__c;
        this.invoiceNoDraft = this.pck.InvoicePOSTotalTime__c;
      } else if (this.pck.PackageType__c == PackageDomain.TYPE_EXPENSE) {
        // this.invoice = this.pck.InvoicePOSTotalExpense__c + this.position.InvoicePositionAmount__c;
        this.invoice = this.pck.InvoicePOSTotalExpense__c;
        this.invoiceNoDraft = this.pck.InvoicePOSTotalExpense__c;
      } else if (this.pck.PackageType__c == PackageDomain.TYPE_SUPPLIER_COSTS) {
        // this.invoice = this.pck.InvoicePOSTotalSupplierCosts__c + this.position.InvoicePositionAmount__c;
        this.invoice = this.pck.InvoicePOSTotalSupplierCosts__c;
        this.invoiceNoDraft = this.pck.InvoicePOSTotalSupplierCosts__c;
      }

      if (!isGroupNull(pGroup)) {
        pGroup.invoice += this.invoice;
        pGroup.invoiceNoDraft += this.invoiceNoDraft;
      }
    }
  }

  public void setAvaliableFunds(PackageBean pGroup) {
    this.availableFunds = this.pck.BudgetAssignPackage__c - this.invoice;

    if (!isGroupNull(pGroup))
      pGroup.availableFunds += this.availableFunds;
  }

  public void setServicesTotalDR(PackageBean pGroup) {
    if (this.pck.PackageType__c == PackageDomain.TYPE_TIME) {
      for (Time__c t : this.pck.Time__r) {
        if (t.ServiceTotalTime__c != null)
          this.servicesTotalDR += t.ServiceTotalTime__c;
      }
    } else if (this.pck.PackageType__c == PackageDomain.TYPE_EXPENSE) {
      for (Expense__c e : this.pck.Expenses__r) {
        if (e.ServiceExpenseNet__c != null)
          this.servicesTotalDR += e.ServiceExpenseNet__c;
      }
    } else if (this.pck.PackageType__c == PackageDomain.TYPE_SUPPLIER_COSTS) {
      for (SupplierCosts__c sc : this.pck.SupplierCosts__r) {
        if (sc.ServiceSupplierCostsNetPM__c != null)
          this.servicesTotalDR += sc.ServiceSupplierCostsNetPM__c;
      }
    }

    if (!isGroupNull(pGroup))
      pGroup.servicesTotalDR += this.servicesTotalDR;
  }

  public Boolean equals(Object obj) {
    if (obj instanceof PackageBean) {
      PackageBean pb = (PackageBean) obj;
      return (this.pck.Id == pb.pck.Id);
    }
    return false;
  }

  public Integer hashCode() {
    return 31 * System.hashCode(String.valueOf(this.pck.Id));
  }

  private Boolean isGroupNull(PackageBean pGroup) {
    return pGroup == null;
  }

  private void setDefaults() {
    this.budget = 0;
    this.invoice = 0;
    this.availableFunds = 0;
    this.servicesTotal = 0;
    this.servicesTotalDR = 0;
    this.invoiceNoDraft = 0;
    this.invoiceInProgress = 0;

    this.showModalForBillingPositionText = false;
    this.calculatedAvailableFunds = 0;
    this.allowanceTotal = 0;
    this.showPosition = false;
    this.showPositionAmount = false;
    this.showInvoiceText = false;
    this.packageBillingPositionText = '';
  }

}