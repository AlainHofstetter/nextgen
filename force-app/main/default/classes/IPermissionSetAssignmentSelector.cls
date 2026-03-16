public interface IPermissionSetAssignmentSelector extends fflib_ISObjectSelector {
	List<PermissionSetAssignment> selectByUserId(Set<Id> ids);
}