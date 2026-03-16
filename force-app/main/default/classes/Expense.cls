public with sharing class Expense extends fflib_SObjectDomain
    implements IExpense {

    public static final String CAR_TRAVEL = 'CarTravel';

    public static IExpense newInstance(List<Expense__c> records) {
        return (IExpense) Application.Domain.newInstance(records);
    }

    public Expense(List<Expense__c> records) {
        super(records);
    }

    public override void onBeforeInsert() {
        setExpenseTracker();
        callInheritedFieldValue(false);
        callUpdateExchangeRate(null);
        setSecExchangeRate();
    }

    public override void onBeforeUpdate(Map<Id,SObject> oldRecords) {
        setExpenseTracker();
        callInheritedFieldValue(false);
        callUpdateExchangeRate(oldRecords);
        setSecExchangeRate();
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
        callParentUpdate(oldRecords);
    }

    public void save(fflib_ISObjectUnitOfWork uow) {

        for (Expense__c e: (List<Expense__c>) records) {
            //setPicklistValues(e);

            if (e.Id == null)
                uow.registerNew(e);
            else
                uow.registerDirty(e);
        }

    }

    private void setPicklistValues(Expense__c e) {
        if (e.PaymentType__c != null)
            e.PaymentType__c = Picklist.get(Expense__c.PaymentType__c, e.PaymentType__c);

        if (e.ExpenseSubType__c != null)
            e.ExpenseSubType__c = Picklist.get(Expense__c.ExpenseSubType__c, e.ExpenseSubType__c);
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

        //if we have currency fields and currency conversion is endabled then update
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
    private void setExpenseTracker() {
        User u = UserSelector.newInstance().selectById(UserInfo.getUserId());

        for (Expense__c e : (List<Expense__c>) records) {
            if (e.Expensetracker__c == null) {
                e.Expensetracker__c = u.InternalContactID__c;
            }
        }

    }

    @TestVisible
    private void setSecExchangeRate() {
        List<DatedConversionRate> rates = DatedConversionRateSelector.newInstance().selectAll();
        Id recordTypeCarTravel = Utils.getRecordTypeIdByDevName('Expense__c', CAR_TRAVEL);

        for (Expense__c e : (List<Expense__c>) records) {

            if (e.RecordTypeId == recordTypeCarTravel) {
                e.Distance__c = e.Distance__c == null ? 0 : e.Distance__c;
                e.DistanceCompensation__c = e.DistanceCompensation__c == null ? 0 : e.DistanceCompensation__c;
                e.ExpenseGross__c = e.Distance__c * e.DistanceCompensation__c;
            }

            if (!e.ExpenseValidatedFinance__c)
                e.ExpenseGrossApproved__c = e.ExpenseGross__c;

            e.LocalCurrencyToCHF__c = getExchangeRate(rates, e.ExpenseDate__c, e.LocalCurrency__c);
            e.CostsExpenseGross__c = e.ExpenseGrossApproved__c * ((e.LocalCurrencyToCHF__c *1) / e.CurrencyRateToCHF__c);

            if (e.VATPercent__c != null) {
                Double numberVAT = Double.valueOf(e.VATPercent__c.replace('%', ''));
                e.CostsExpenseNet__c = e.CostsExpenseGross__c / (1 + numberVAT/100);
            }

            if (!e.ExpenseValidatedProjectResponsible__c)
                e.ServiceExpenseNet__c = e.CostsExpenseNet__c;

        }


    }

    @TestVisible
    private Double getExchangeRate(List<DatedConversionRate> rates, Date dateOfRate, String isoCode) {
        Double exchangeRate = 0;
        for(DatedConversionRate r : rates) {
            if(r.IsoCode == isoCode && r.StartDate <= dateOfRate && r.NextStartDate > dateOfRate && r.ConversionRate > 0) {
                exchangeRate = 1/r.ConversionRate;
                break;
            }
        }
        return exchangeRate;
    }

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> sObjectList) {
            return new Expense(sObjectList);
        }
    }
}