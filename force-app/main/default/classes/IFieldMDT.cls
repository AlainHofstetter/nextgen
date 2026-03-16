public interface IFieldMDT extends fflib_ISObjectDomain  {
	void controlDeletion(List<SObject> recordsToCheck);
	void updateExchangeRate(List<SObject> newRecords, Map<Id,SObject> oldRecords);
}