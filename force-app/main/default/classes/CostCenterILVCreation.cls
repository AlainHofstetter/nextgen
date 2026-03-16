public with sharing class CostCenterILVCreation {

  @AuraEnabled
  public Id ccId;

  @AuraEnabled
  public String name; // CostCenter Name

  @AuraEnabled
  public Package__c pck;

  @AuraEnabled
  public Decimal services; // G1 & H1

  @AuraEnabled
  public Decimal revenue; // G2 & H2

  @AuraEnabled
  public Decimal revenueRate; // G3 & H3

  @AuraEnabled
  public Decimal servicesDR; // G4 & H4

  @AuraEnabled
  public Decimal revenueNew; // G5 & H5 always zero from apex side

  @AuraEnabled
  public Decimal revenueRateDR; // G6 & H6 always zero from apex side

  @AuraEnabled
  public ILVPos__c position; // it will be null for Leading CC

  public Invoice__c inv;
  public Boolean isLeading;


  /**
   * Group constructor
   * @p subpackage to be summed up
   * @isLeadingCC leading cost center flag
   * @dateFrom & @dateTo date range for the calculation
   **/
  public CostCenterILVCreation(Id ccId, String name, Package__c p, Invoice__c inv, Boolean isLeadingCC) {
    this.ccId = ccId;
    this.name = name;
    this.pck = p;
    this.inv = inv;
    this.isLeading = isLeadingCC;
    this.setDefaults();

    if (!isLeadingCC)
        this.setRevenueReceiving(null);
  }

  /**
   * Subgroup constructor
   * @p subpackage to be summed up
   * @pGroup parent package to be proccessed alongside to its subpackage
   * @isLeadingCC leading cost center flag
   * @dateFrom & @dateTo date range for the calculation
   **/
  public CostCenterILVCreation(Id ccId, String name, Package__c p, Invoice__c inv,
          CostCenterILVCreation ccGroup, Boolean isLeadingCC, DateRange dates) {
    this.ccId = ccId;
    this.name = name;
    this.pck = p;
    this.inv = inv;
    this.isLeading = isLeadingCC;
    this.setDefaults();
    this.sumup(ccGroup, dates);
  }

  private void sumup(CostCenterILVCreation ccGroup, DateRange dates) {
    if (isLeading) {
      setServicesLeading(ccGroup);
      setRevenueLeading(ccGroup);
      setRevenueRate(ccGroup);
      setServicesDRLeading(ccGroup, dates);
    } else {
      setServicesReceiving(ccGroup);
      setRevenueReceiving(ccGroup);
      setRevenueRate(ccGroup);
      setServicesDRReceiving(ccGroup, dates);
    }
  }

  public void setServicesLeading(CostCenterILVCreation ccGroup) {
    if (this.pck.PackageType__c == PackageDomain.TYPE_TIME) {
      for (Time__c t : this.pck.Time__r) {
        if (t.ServiceTotalTime__c != null && t.TimeTrackerCostCenter__c == ccId)
          this.services += t.ServiceTotalTime__c;
      }
    } else if (this.pck.PackageType__c == PackageDomain.TYPE_EXPENSE) {
      for (Expense__c e : this.pck.Expenses__r) {
        if (e.ServiceExpenseNet__c != null && e.ExpensetrackerCostCenter__c == ccId)
          this.services += e.ServiceExpenseNet__c;
      }
    } else if (this.pck.PackageType__c == PackageDomain.TYPE_SUPPLIER_COSTS) {
      for (SupplierCosts__c sc : this.pck.SupplierCosts__r) {
        if (sc.ServiceSupplierCostsNetPM__c != null && sc.ProjectCostCenter__c == ccId)
          this.services += sc.ServiceSupplierCostsNetPM__c;
      }
    }

    if (!isGroupNull(ccGroup))
      ccGroup.services += this.services;
  }

  public void setServicesReceiving(CostCenterILVCreation ccGroup) {
    if (this.pck.PackageType__c == PackageDomain.TYPE_TIME) {
      for (Time__c t : this.pck.Time__r) {
        if (t.ServiceTotalTime__c != null && t.TimeTrackerCostCenter__c == ccId)
          this.services += t.ServiceTotalTime__c;
      }
    }

    if (!isGroupNull(ccGroup))
      ccGroup.services += this.services;

  }

  public void setRevenueLeading(CostCenterILVCreation ccGroup) {
    Boolean isSubpackage = (ccGroup != null);
    Boolean hasInvPosition = this.pck != null && this.pck.InvoicePos__r != null && this.pck.InvoicePos__r.size() == 1;
    Boolean hasILVPosition = this.pck != null && this.pck.ILVPos__r != null && this.pck.ILVPos__r.size() > 0;

    if (hasInvPosition && hasILVPosition) {
      InvoicePos__c invPos = this.pck.InvoicePos__r;
      Decimal receivingRevenues = 0;

      for (ILVPos__c ip: this.pck.ILVPos__r) {
        if (ip.ILVType__c == 'Time' && ip.CostCenterILVReceiver__c != this.pck.ProjectName__r.ProjectCostCenter__c)
          receivingRevenues += ip.ILVPositionAmount__c;
      }

      if (receivingRevenues == 0)
        this.revenue = invPos.InvoicePositionAmount__c;
      else
        this.revenue = invPos.InvoicePositionAmount__c / receivingRevenues;

      if(isSubpackage && !isGroupNull(ccGroup))
        ccGroup.revenue += this.revenue;
    }

  }

  public void setRevenueReceiving(CostCenterILVCreation ccGroup) {
    Boolean isSubpackage = (ccGroup != null);
    Boolean hasILVPosition = this.pck != null && this.pck.ILVPos__r != null && this.pck.ILVPos__r.size() > 0;

    if (hasILVPosition) {

      for (ILVPos__c ip: this.pck.ILVPos__r) {
        if (ip.CostCenterILVReceiver__c == ccId) {
            if (inv != null && inv.Id == ip.InvoiceName__c)
                this.position = ip;

          if (ip.PackageSubType__c == 'WorkTime'
                  && ip.InvoiceName__r != null
                  && ip.InvoiceName__r.InvoiceStatus__c != Invoice.STATUS_DRAFT)
            this.revenue += ip.ILVPositionAmount__c;
        }
      }

      if(isSubpackage && !isGroupNull(ccGroup))
        ccGroup.revenue += this.revenue;
    }

  }

  public void setRevenueRate(CostCenterILVCreation ccGroup) {
    if (this.services <= 0) return;

    this.revenueRate = (this.revenue / this.services) * 100;

    if (!isGroupNull(ccGroup))
      ccGroup.revenueRate += this.revenueRate;
  }

  public void setServicesDRLeading(CostCenterILVCreation ccGroup, DateRange dates) {
    if (dates.isNull()) return;

    if (this.pck.PackageType__c == PackageDomain.TYPE_TIME) {
      for (Time__c t : this.pck.Time__r) {
        if (t.ServiceTotalTime__c != null && dates.isInBetween(t.DateFrom__c) && t.TimeTrackerCostCenter__c == ccId)
          this.servicesDR += t.ServiceTotalTime__c;
      }
    } else if (this.pck.PackageType__c == PackageDomain.TYPE_EXPENSE) {
      for (Expense__c e : this.pck.Expenses__r) {
        if (e.ServiceExpenseNet__c != null && dates.isInBetween(e.ExpenseDate__c) && e.ExpensetrackerCostCenter__c == ccId)
          this.servicesDR += e.ServiceExpenseNet__c;
      }
    } else if (this.pck.PackageType__c == PackageDomain.TYPE_SUPPLIER_COSTS) {
      for (SupplierCosts__c sc : this.pck.SupplierCosts__r) {
        if (sc.ServiceSupplierCostsNetPM__c != null && dates.isInBetween(sc.SupplierCostsDate__c) && sc.ProjectCostCenter__c == ccId)
          this.servicesDR += sc.ServiceSupplierCostsNetPM__c;
      }
    }

    if (!isGroupNull(ccGroup))
      ccGroup.servicesDR += this.servicesDR;
  }

  public void setServicesDRReceiving(CostCenterILVCreation ccGroup, DateRange dates) {
    if (dates.isNull()) return;

    if (this.pck.PackageType__c == PackageDomain.TYPE_TIME) {
      for (Time__c t : this.pck.Time__r) {
        if (t.ServiceTotalTime__c != null && dates.isInBetween(t.DateFrom__c) && t.TimeTrackerCostCenter__c == ccId)
          this.servicesDR += t.ServiceTotalTime__c;
      }
    }

    if (!isGroupNull(ccGroup))
      ccGroup.servicesDR += this.servicesDR;
  }

  private void setDefaults() {
    this.services = 0;
    this.revenue = 0;
    this.revenueRate = 0;
    this.servicesDR = 0;
    this.revenueNew = 0;
    this.revenueRateDR = 0;
  }

  private Boolean isGroupNull(CostCenterILVCreation ccGroup) {
    return ccGroup == null;
  }
}