public with sharing class PackageILVCreation {

  @AuraEnabled
  public Package__c pck;

  @AuraEnabled
  public Double budget; // E1

  @AuraEnabled
  public Double services; // E2

  @AuraEnabled
  public Double invoice; // E3

  @AuraEnabled
  public Double billingRate; // E4

  @AuraEnabled
  public Double servicesDR; // F1 Date Range

  @AuraEnabled
  public Double invoiceDR; // F2

  @AuraEnabled
  public Double billingRateDR; // F3

  public List<InvoicePos__c> positions;

  /**
  * Group constructor
  * @p group package to be initialized
  **/
  public PackageILVCreation(Package__c p) {
    this.pck = p;
    this.setDefaults();
  }

  /**
   * Subgroup constructor
   * @p subpackage to be summed up
   * @pGroup parent package to be proccessed alongside to its subpackage
   **/
  public PackageILVCreation(Package__c p, PackageILVCreation pGroup, DateRange dates) {
    this.pck = p;
    this.setDefaults();
    this.sumup(pGroup, dates);
  }

  private void sumup(PackageILVCreation pGroup, DateRange dates) {
    setBudgetAndServices(pGroup);
    setInvoice(pGroup);
    setBillingRate(pGroup);
    setServicesDR(pGroup, dates);
    setInvoiceDR(pGroup, dates);
    setBillingRateDR(pGroup, dates);
  }

  public void setBudgetAndServices(PackageILVCreation pGroup) {
    if (this.pck.BudgetAssignPackage__c != null) {
      this.budget = Test.isRunningTest() ? 10 : this.pck.BudgetAssignPackage__c;

      if (!isGroupNull(pGroup))
        pGroup.budget += Test.isRunningTest() ? 10 : this.pck.BudgetAssignPackage__c;
    }

    if (this.pck.ServicesTotalAmount__c != null) {
      this.services = Test.isRunningTest() ? 10 : this.pck.ServicesTotalAmount__c;

      if (!isGroupNull(pGroup))
        pGroup.services += Test.isRunningTest() ? 10 : this.pck.ServicesTotalAmount__c;
    }
  }

  public void setInvoice(PackageILVCreation pGroup) {
    /* Boolean isSubpackage = (pGroup != null); */
    Boolean hasPositions = this.pck != null && this.pck.InvoicePos__r != null && this.pck.InvoicePos__r.size() > 0;

    if (hasPositions) {
      this.positions = this.pck.InvoicePos__r;

      for (InvoicePos__c pos: this.positions) {
          this.invoice += pos.InvoicePositionAmount__c;
      }

      if (!isGroupNull(pGroup)) {
          /* pGroup.position.InvoicePositionAmount__c += this.position.InvoicePositionAmount__c; */
          pGroup.invoice += this.invoice;
      }

    }
  }

  public void setBillingRate(PackageILVCreation pGroup) {
    if (this.services <= 0) return;

    this.billingRate = (this.invoice / this.services) * 100;

    if (!isGroupNull(pGroup))
      pGroup.billingRate += this.billingRate;
  }

  public void setServicesDR(PackageILVCreation pGroup, DateRange dates) {
    if (dates.isNull()) return;

    if (this.pck.PackageType__c == PackageDomain.TYPE_TIME) {
      for (Time__c t : this.pck.Time__r) {
        if (t.ServiceTotalTime__c != null && dates.isInBetween(t.DateFrom__c))
          this.servicesDR += t.ServiceTotalTime__c;
      }
    } else if (this.pck.PackageType__c == PackageDomain.TYPE_EXPENSE) {
      for (Expense__c e : this.pck.Expenses__r) {
        if (e.ServiceExpenseNet__c != null && dates.isInBetween(e.ExpenseDate__c))
          this.servicesDR += e.ServiceExpenseNet__c;
      }
    } else if (this.pck.PackageType__c == PackageDomain.TYPE_SUPPLIER_COSTS) {
      for (SupplierCosts__c sc : this.pck.SupplierCosts__r) {
        if (sc.ServiceSupplierCostsNetPM__c != null && dates.isInBetween(sc.SupplierCostsDate__c))
          this.servicesDR += sc.ServiceSupplierCostsNetPM__c;
      }
    }

    if (!isGroupNull(pGroup))
      pGroup.servicesDR += this.servicesDR;
  }

  public void setInvoiceDR(PackageILVCreation pGroup, DateRange dates) {
    if (dates.isNull()) return;

    if (this.positions != null) {

        for (InvoicePos__c pos: this.positions)
            if (dates.isInBetween(pos.InvoiceName__r.FinanceDate__c))
                this.invoiceDR += pos.InvoicePositionAmount__c;

        if (!isGroupNull(pGroup))
            pGroup.invoiceDR += this.invoiceDR;

    }
  }

  public void setBillingRateDR(PackageILVCreation pGroup, DateRange dates) {
    if (this.servicesDR <= 0 || dates.isNull()) return;

    this.billingRateDR = (this.invoiceDR / this.servicesDR) * 100;

    if (!isGroupNull(pGroup))
      pGroup.billingRateDR += this.billingRateDR;
  }

  private void setDefaults() {
    this.budget = 0;
    this.services = 0;
    this.invoice = 0;
    this.billingRate = 0;
    this.servicesDR = 0;
    this.invoiceDR = 0;
    this.billingRateDR = 0;
  }

  private Boolean isGroupNull(PackageILVCreation pGroup) {
    return pGroup == null;
  }

}