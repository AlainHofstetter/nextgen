public interface IInheritedFieldValueMDTSelector extends fflib_ISObjectSelector {

  List<InheritedFieldValue__mdt> selectByTargetObj(String typeName);

  List<InheritedFieldValue__mdt> selectActives();

}