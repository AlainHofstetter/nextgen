public without sharing class TimeDomain extends fflib_SObjectDomain
  implements ITimeDomain {

  public static final String EMPLOYEE_RATE = 'EmployeeSpecificRate';
  public static final String PACKAGE_RATE = 'PackageRate';
  public static final String ABACUSTIME_TYPE_DEFAULT = 'Default';

  public static ITimeDomain newInstance(List<Time__c> records) {
    return (ITimeDomain) Application.Domain.newInstance(records);
  }

  public TimeDomain(List<Time__c> records) {
    super(records);
  }

  public override void onBeforeInsert() {
    setContactId();
    callInheritedFieldValue(false);
    callUpdateExchangeRate(null);
    setRate();
    setAbacusTimeType();
    setTimeDuration();
  }

  public override void onBeforeUpdate(Map<Id,SObject> oldRecords) {
    callInheritedFieldValue(false);
    callUpdateExchangeRate(oldRecords);
    setRate();
    setAbacusTimeType();
    setTimeDuration();
  }

  public override void onBeforeDelete() {
    List<Field__mdt> fields = FieldMDTSelector.newInstance().selectDeletionControlFields(this.getSObjectType().getDescribe().getName());
    IFieldMDT fieldDomain = FieldMDT.newInstance(fields);
    fieldDomain.controlDeletion(records);
  }

  public override void onAfterInsert() {
    callParentUpdate(null);
  }

  public override void onAfterUpdate(Map<Id,SObject> oldRecords) {
    fflib_SObjectDomain.getTriggerEvent(TimeDomain.class).disableAfterUpdate();
    callParentUpdate(oldRecords);
  }

  public void save(fflib_ISObjectUnitOfWork uow) {

    for (Time__c t: (List<Time__c>) records) {
      if (t.Id == null)
        uow.registerNew(t);
      else
        uow.registerDirty(t);
    }

  }

  @TestVisible
  private void setRate(){

    Set<Id> packageIds = new Set<Id>();
    for(Time__c t : (List<Time__c>) records){
      packageIds.add(t.Package__c);
    }

    Map<Id, Package__c> packageMap = New Map<Id,Package__c>(PackageSelector.newInstance().selectById(packageIds));

    Set<Id> projectIds = new Set<ID>();
    for(Package__c p : packageMap.values()){
      projectIds.add(p.ProjectName__c);
    }

    List<ProjectEmployeeRate__c> perList = ProjectEmployeeRateSelector.newInstance().selectByProjectId(projectIds);
    for(Time__c t : (List<Time__c>) records){
      Package__c p = packageMap.get(t.Package__c);

      t.RateHour__c = p.PackageRateHour__c;
      t.RateOrigin__c = PACKAGE_RATE;

      if (p.EmployeeSpecificRate__c){
        for(ProjectEmployeeRate__c per : perList){
          if(per.ProjectEmployee__c == t.Timetracker__c && per.Project__c == p.ProjectName__c){
            t.RateHour__c = per.ProjectEmployeeRateHour__c;
            t.RateOrigin__c = EMPLOYEE_RATE;
            break;
          }
        }
      }
    }
  }

  @TestVisible
  private void setContactId(){
    User u = UserSelector.newInstance().selectById(UserInfo.getUserId());
    for(Time__c t : (List<Time__c>) records){
      if (t.Timetracker__c == null){
        t.Timetracker__c = u.InternalContactID__c;
      }
    }
  }

  @TestVisible
  private void callParentUpdate(Map<Id,SObject> oldRecords) {
    fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
    List<ParentObjectUpdate__mdt> pous = ParentObjectUpdateMDTSelector.newInstance().selectBySourceObj(this.getSObjectType().getDescribe().getName());
    IParentObjectUpdateMDT pouDomain = ParentObjectUpdateMDT.newInstance(pous);

    pouDomain.go(uow, records, oldRecords);
    uow.commitWork();
  }

  @TestVisible
  private void callUpdateExchangeRate(Map<Id,SObject> oldRecords){
    List<Object__mdt> objs = ObjectMDTSelector.newInstance().selectCurrencyFields(this.getSObjectType().getDescribe().getName());

    if(objs.size() > 0 && objs[0].Fields__r != null){
      IFieldMDT fieldDomain = FieldMDT.newInstance(objs[0].Fields__r);
      fieldDomain.updateExchangeRate(records, oldRecords);
    }
  }

  @TestVisible
  private void callInheritedFieldValue(Boolean isUpdate) {
    List<InheritedFieldValue__mdt> inheritedFValues = InheritedFieldValueMDTSelector.newInstance().selectByTargetObj(this.getSObjectType().getDescribe().getName());
    IInheritedFieldValueMDT inheritedFVDomain = InheritedFieldValueMDT.newInstance(inheritedFValues);

    if (isUpdate) {
      fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
      inheritedFVDomain.go(uow, records);
      uow.commitWork();
    } else {
      inheritedFVDomain.go(null, records);
    }

  }

  @TestVisible
  private void setAbacusTimeType() {
    Map<Id, List<Time__c>> times = new Map<Id, List<Time__c>>();
    Set<Id> contactIds = new Set<Id>();

    for (Time__c t : (List<Time__c>) records) {
      List<Time__c> listTimes = times.get(t.Package__c);

      if (listTimes == null || listTimes.isEmpty()) {
        times.put(t.Package__c, new List<Time__c>{t});
      } else {
        listTimes.add(t);
      }
      contactIds.add(t.Timetracker__c);
    }
    System.debug('***contactIds ' + contactIds );

    List<Package__c> packages = PackageSelector.newInstance().selectById(times.keySet());
    Map<Id, Contact> contacts = new Map<Id, Contact>(ContactSelector.newInstance().selectById(contactIds));
    System.debug('***contacts ' + contacts);

    for (Package__c p : (List<Package__c>) packages) {

      for (Time__c t : times.get(p.Id)) {
        System.debug('***time ' + t );
        System.debug('***time ' + t.Timetracker__c );
        if (p.AbacusTimeType__c == ABACUSTIME_TYPE_DEFAULT) {
          t.AbacusTimeType__c = contacts.get(t.Timetracker__c).AbacusDefaultTimeType__c;
        } else {
          t.AbacusTimeType__c = p.AbacusTimeType__c;
        }
      }

    }

  }

  @TestVisible
  private void setTimeDuration() {

    for (Time__c t : (List<Time__c>) records) {
      if (t.DurationHhMm__c != null) {
        String[] brokenDuration = t.DurationHhMm__c.split(':');
        
        if (brokenDuration.size() != 2) continue;
            
        Double hours = Double.valueOf(brokenDuration[0]);
        Double minutes = Double.valueOf(brokenDuration[1]);

        t.DurationHhMmN__c = hours + (minutes / (6*10));
      }
    }

  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new TimeDomain(sObjectList);
    }
  }
}