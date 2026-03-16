public interface IParentObjectUpdateMDTSelector extends fflib_ISObjectSelector {

  List<ParentObjectUpdate__mdt> selectBySourceObj(String typeName);

  List<ParentObjectUpdate__mdt> selectActives();

}