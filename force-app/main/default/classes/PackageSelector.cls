public with sharing class PackageSelector extends fflib_SObjectSelector
  implements IPackageSelector {

  public static IPackageSelector newInstance() {
    return (IPackageSelector) Application.Selector.newInstance(Package__c.SObjectType);
  }

  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField> (
      getSObjectType().getDescribe().fields.getMap().values()
    );
  }

  public Schema.SObjectType getSObjectType() {
    return Package__c.sObjectType;
  }

  public override String getOrderBy() {
    return 'PackageSortNr__c ASC, RecordType.Name ASC, Name ASC';
  }

  public List<Package__c> selectAll(){
    fflib_QueryFactory query = newQueryFactory();
    query.selectFields(new Set<String>{'PackageSuperior__r.PackageStatus__c','ProjectName__r.ProjectStatus__c'});
    return (List<Package__c>) Database.query(query.toSOQL());
  }

  public List<Package__c> selectById(Set<Id> ids){
    fflib_QueryFactory query = newQueryFactory();
    query.setCondition('Id in :ids');
    return (List<Package__c>) Database.query(query.toSOQL());
  }

  public List<Package__c> selectByProjectId(Set<Id> ids) {
    fflib_QueryFactory query = newQueryFactory();
    query.selectFields(new Set<String> {
      'RecordType.Name',
      'Segment__r.Name',
      'ProjectName__r.Name',
      'ProjectName__r.ProjectCostCenter__r.Name',
      'ProjectName__r.ProjectCurrency__c',
      'ProjectName__r.ProjectRateHour__c',
      'ProjectName__r.ProjectNr__c',
      'ProjectName__r.ProjectType__c',
      'ProjectName__r.ProjectSubType__c'
    });
    query.setCondition('ProjectName__c in :ids');

    String soql = query.toSOQL()
        .replaceFirst('RecordType.Name', 'toLabel(RecordType.Name)')
        .replaceFirst('PackageSubType__c', 'toLabel(PackageSubType__c)')
        .replaceFirst('PackageStatus__c', 'toLabel(PackageStatus__c)');

    return (List<Package__c>) Database.query(soql);
  }

  public List<Package__c> byProjectId(Set<Id> ids) {
    fflib_QueryFactory query = newQueryFactory();
    query.setCondition('ProjectName__c in :ids');
    return (List<Package__c>) Database.query(query.toSOQL());
  }

  public List<Package__c> selectBySuperiorExcludedFields(Set<Id> ids, Set<String> excludedFields) {
    fflib_QueryFactory query = newQueryFactory(false);

    for (Schema.SObjectField f: getSObjectFieldList()) {
      String field = f.getDescribe().getName();
      if (!excludedFields.contains(field)) {
        query.selectField(field);
      }
    }

    query.setCondition('PackageSuperior__c in :ids');
    return (List<Package__c>) Database.query(query.toSOQL());
  }

  public List<Package__c> selectByProjectExcludedFields(Set<Id> ids, Set<String> excludedFields) {
    fflib_QueryFactory query = newQueryFactory(false);

    for (Schema.SObjectField f: getSObjectFieldList()) {
      String field = f.getDescribe().getName();
      if (!excludedFields.contains(field)) {
        query.selectField(field);
      }
    }

    query.setCondition('ProjectName__c in :ids');
    return (List<Package__c>) Database.query(query.toSOQL());
  }

  public ProjectStructureBean selectProjectStructure(Id projectId, String dateFrom, String dateTo) {
    String queryCondition = '';
    Invoice__c inv = InvoiceSelector.newInstance().draftByProject(projectId, Invoice.RECORD_TYPE_INVOICE);

    if (inv != null && dateFrom == null && dateTo == null) {
      dateFrom = Utils.formatDate(inv.PeriodFrom__c, 'yyyy-MM-dd');
      dateTo = Utils.formatDate(inv.PeriodUntil__c, 'yyyy-MM-dd');
    }

    fflib_QueryFactory query = newQueryFactory(false, false, false);
    query.selectFields(ProjectStructureBean.projectPackageFields);
    queryCondition = 'ProjectName__c = \'' + projectId + '\'';
    query.setCondition(queryCondition);

    if (dateFrom != null && dateTo != null) {
      fflib_QueryFactory timeQuery = new TimeSelector().addQueryFactorySubselect(query);
      timeQuery.selectFields(ProjectStructureBean.timeFields);
      queryCondition = 'DateFrom__c >= ' + dateFrom + ' AND DateFrom__c <= ' + dateTo;
      timeQuery.setCondition(queryCondition);

      fflib_QueryFactory expenseQuery = new ExpenseSelector().addQueryFactorySubselect(query);
      expenseQuery.selectFields(ProjectStructureBean.expenseFields);
      queryCondition = 'ExpenseDate__c >= ' + dateFrom + ' AND ExpenseDate__c <= ' + dateTo;
      expenseQuery.setCondition(queryCondition);

      fflib_QueryFactory scQuery = new SupplierCostsSelector().addQueryFactorySubselect(query);
      scQuery.selectFields(ProjectStructureBean.supplierCostsFields);
      queryCondition = 'SupplierCostsDate__c >= ' + dateFrom + ' AND SupplierCostsDate__c <= ' + dateTo;
      scQuery.setCondition(queryCondition);
    }

    if (inv != null) {
      fflib_QueryFactory invoicePosQuery = new InvoicePositionSelector().addQueryFactorySubselect(query);
      invoicePosQuery.selectFields(ProjectStructureBean.invoicePosFields);
      queryCondition = 'InvoiceName__c = \'' + inv.Id + '\'';
      invoicePosQuery.setCondition(queryCondition);
    }

    String soql = query.toSOQL()
        .replaceFirst('RecordType.Name', 'toLabel(RecordType.Name)')
        .replaceFirst('PackageSubType__c', 'toLabel(PackageSubType__c)')
        .replaceFirst('ExpenseBillingType__c', 'toLabel(ExpenseBillingType__c)');

    List<Package__c> packages = (List<Package__c>) Database.query(soql);
    return new ProjectStructureBean(inv, packages);
  }

  public ILVCreation selectILVInfo(Id projectId, String dateFrom, String dateTo) {

    Invoice__c inv = InvoiceSelector.newInstance().draftByProject(projectId, Invoice.RECORD_TYPE_ILV);

    if (inv != null && dateFrom == null && dateTo == null) {
      dateFrom = Utils.formatDate(inv.PeriodFrom__c, 'yyyy-MM-dd');
      dateTo = Utils.formatDate(inv.PeriodUntil__c, 'yyyy-MM-dd');
    }

    fflib_QueryFactory query = newQueryFactory(false, false, false);
    query.selectFields(ILVCreation.projectPackageFields);
    query.setCondition('ProjectName__c = \'' + projectId + '\'');

    fflib_QueryFactory timeQuery = new TimeSelector().addQueryFactorySubselect(query);
    timeQuery.selectFields(ILVCreation.timeFields);
    
    String queryCondition = '';
    if(dateFrom != null && dateTo != null) {
      queryCondition
          = (dateFrom != null && dateTo != null)
          ? queryCondition + 'DateFrom__c >= ' + dateFrom + ' AND DateFrom__c <= ' + dateTo
          : queryCondition;
      timeQuery.setCondition(queryCondition);
    }

    fflib_QueryFactory expenseQuery = new ExpenseSelector().addQueryFactorySubselect(query);
    expenseQuery.selectFields(ILVCreation.expenseFields);
    queryCondition = '';
    if(dateFrom != null && dateTo != null) {
        queryCondition
          = (dateFrom != null && dateTo != null)
          ? queryCondition + 'ExpenseDate__c >= ' + dateFrom + ' AND ExpenseDate__c <= ' + dateTo
          : queryCondition;
      expenseQuery.setCondition(queryCondition);
    }

    fflib_QueryFactory scQuery = new SupplierCostsSelector().addQueryFactorySubselect(query);
    scQuery.selectFields(ILVCreation.supplierCostsFields);
    
    queryCondition = '';
    if(dateFrom != null && dateTo != null) {
      queryCondition
        = (dateFrom != null && dateTo != null)
        ? queryCondition + 'SupplierCostsDate__c >= ' + dateFrom + ' AND SupplierCostsDate__c <= ' + dateTo 
        : queryCondition;
      scQuery.setCondition(queryCondition);
    }

    fflib_QueryFactory invoicePosQuery = new InvoicePositionSelector().addQueryFactorySubselect(query);
    invoicePosQuery.selectFields(ILVCreation.invoicePosFields);
    invoicePosQuery.setCondition('InvoiceName__r.CancellationInvoiceRelation__c = NULL AND InvoiceName__r.RecordType.DeveloperName = \'Invoice\' AND InvoiceName__r.InvoiceStatus__c != \'Draft\'');

    fflib_QueryFactory ilvPosQuery = new ILVPosSelector().addQueryFactorySubselect(query);
    ilvPosQuery.selectFields(ILVCreation.ilvPosFields);
    ilvPosQuery.setCondition('InvoiceName__r.RecordType.DeveloperName = \'ILV\' AND ILVType__c IN (\'Time\', \'Group\')');
    System.debug(query.toSOQL());
    List<Package__c> packages = (List<Package__c>) Database.query(query.toSOQL());
    return new ILVCreation(inv, packages, dateFrom, dateTo);
  }

  public Model selectFull(Params parameters) {
    fflib_QueryFactory query = newQueryFactory(false);
    query.selectField('Name');

    String queryCondition = 'ProjectName__c = \'' + parameters.projectId + '\'';
    queryCondition = parameters.packageId != null ? queryCondition + ' AND Id = \'' + parameters.packageId + '\'' : queryCondition;
    query.setCondition(queryCondition);

    if (parameters.dateFrom == '' || parameters.dateTo == '') {
        parameters.dateFrom = null;
        parameters.dateTo = null;
    }

    if (parameters.showTime) {
      fflib_QueryFactory timeQuery = new TimeSelector().addQueryFactorySubselect(query);
      timeQuery.selectFields(timeFields);

      queryCondition = 'Id != NULL';

      queryCondition
        = (parameters.dateFrom != null && parameters.dateTo != null)
        ? queryCondition + ' AND (DateFrom__c >= ' + parameters.dateFrom + ' AND DateFrom__c <= ' + parameters.dateTo + ')'
        : queryCondition;

      queryCondition
        = parameters.showValidatedInvoicedCosts
        ? queryCondition
        : queryCondition + ' AND TimeValidatedProjectResponsible__c = false ';

      if (queryCondition != null)
        timeQuery.setCondition(queryCondition);
    }

    if (parameters.showExpense) {
      fflib_QueryFactory expenseQuery = new ExpenseSelector().addQueryFactorySubselect(query);
      expenseQuery.selectFields(expenseFields);

      queryCondition = 'Id != NULL';

      queryCondition
        = (parameters.dateFrom != null && parameters.dateTo != null)
        ? queryCondition + ' AND (ExpenseDate__c >= ' + parameters.dateFrom + ' AND ExpenseDate__c <= ' + parameters.dateTo + ')'
        : queryCondition;

      queryCondition
        = parameters.showValidatedInvoicedCosts
        ? queryCondition
        : queryCondition + ' AND ExpenseValidatedProjectResponsible__c = false ';

      if (queryCondition != null)
        expenseQuery.setCondition(queryCondition);
    }

    if (parameters.showSupplierCosts) {
      fflib_QueryFactory scQuery = new SupplierCostsSelector().addQueryFactorySubselect(query);
      scQuery.selectFields(supplierCostsFields);

      queryCondition = 'Id != NULL';

      queryCondition
        = (parameters.dateFrom != null && parameters.dateTo != null)
        ? queryCondition + ' AND (SupplierCostsDate__c >= ' + parameters.dateFrom + ' AND SupplierCostsDate__c <= ' + parameters.dateTo + ')'
        : queryCondition;

      queryCondition
        = parameters.showValidatedInvoicedCosts
        ? queryCondition
        : queryCondition + ' AND SupplierCostsInvoicedPM__c = false ';

      if (queryCondition != null)
        scQuery.setCondition(queryCondition);
    }

    String soql = query.toSOQL()
        .replaceFirst('ServiceType__c', 'toLabel(ServiceType__c)')
        .replaceFirst('RecordType.Name', 'toLabel(RecordType.Name)')
        .replaceFirst('ExpenseSubType__c', 'toLabel(ExpenseSubType__c)');

    List<Package__c> packages = (List<Package__c>) Database.query(soql);

    return new Model(packages);
  }

  public class Params {

    @AuraEnabled
    public Id projectId;

    @AuraEnabled
    public Id packageId;

    @AuraEnabled
    public Boolean isClosed;

    @AuraEnabled
    public Boolean showTime;

    @AuraEnabled
    public String dateFrom;

    @AuraEnabled
    public String dateTo;

    @AuraEnabled
    public Boolean showExpense;

    @AuraEnabled
    public Boolean showSupplierCosts;

    @AuraEnabled
    public Boolean showValidatedInvoicedCosts;

    public Params() {
      this.showTime = false;
      this.showExpense = false;
      this.showSupplierCosts = false;
      this.showValidatedInvoicedCosts = false;
    }

  }

  public class Model {

    @AuraEnabled
    public List<Time__c> times;

    @AuraEnabled
    public List<Expense__c> expenses;

    @AuraEnabled
    public List<SupplierCosts__c> supplierCosts;

    public Model(List<Package__c> packages) {
      buildModel(packages);
    }

    private void buildModel(List<Package__c> packages) {
      times = new List<Time__c>();
      expenses = new List<Expense__c>();
      supplierCosts = new List<SupplierCosts__c>();

      for (Package__c pck: packages) {
        if (pck.Time__r.size() > 0)
          times.addAll(pck.Time__r);

        if (pck.Expenses__r.size() > 0)
          expenses.addAll(pck.Expenses__r);

        if (pck.SupplierCosts__r.size() > 0)
          supplierCosts.addAll(pck.SupplierCosts__r);
      }

    }

  }

  public static Set<String> timeFields = new Set<String> {
    'DateFrom__c',
    'Package__r.Name',
    'ServiceType__c',
    'TimeTracker__r.Name',
    'Description__c',
    'Name',
    'DurationHhMm__c',
    'RateHour__c',
    'ServiceTotalTime__c',
    'OutOfScope__c',
    'TimeValidatedProjectResponsible__c'
  };

  public static Set<String> expenseFields = new Set<String> {
    'Name',
    'ExpenseDate__c',
    'Package__r.Name',
    'RecordType.Name',
    'ExpenseTracker__r.Name',
    'ExpenseSubType__c',
    'ServiceExpenseNet__c',
    'ExpenseValidatedProjectResponsible__c'
  };

  public static Set<String> supplierCostsFields = new Set<String> {
    'SupplierCostsDate__c',
    'Name',
    'PackageName__r.Name',
    'SupplierInvoice__r.BillerAccount__c',
    'SupplierInvoice__r.BillerAccount__r.Name',
    'SupplierInvoice__r.OrderReference__c',
    'SupplierInvoicePositionText__c',
    'SupplierCostsInvoicedPM__c',
    'ServiceSupplierCostsNet__c',
    'CostsSupplierCostsNet__c',
    'CostsSupplierCostsNetCHF__c'
  };


}