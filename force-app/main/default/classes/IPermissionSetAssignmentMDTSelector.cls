public interface IPermissionSetAssignmentMDTSelector extends fflib_ISObjectSelector {
	List<PermissionSetAssigment__mdt> selectBySourceObj(String typeName);
}