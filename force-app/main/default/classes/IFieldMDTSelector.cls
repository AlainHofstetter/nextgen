public interface IFieldMDTSelector extends fflib_ISObjectSelector {

  List<Field__mdt> selectDeletionControlFields(String typeName);

  Set<String> selectExcludedFromTemplate(String typeName);

  List<Field__mdt> getFieldMDTTest();

}