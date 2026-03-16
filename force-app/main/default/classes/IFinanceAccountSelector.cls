public interface IFinanceAccountSelector extends fflib_ISObjectSelector {

  FinanceAccount__c selectByCostCenterAndType(Id costCenter, String type);

  List<FinanceAccount__c> selectByCostCenterAndType(Set<Id> ccIds, Set<String> types);

  List<FinanceAccount__c> selectByCostCenterAndType(Set<Id> ccIds, Set<String> types, Set<String> subTypes);

}