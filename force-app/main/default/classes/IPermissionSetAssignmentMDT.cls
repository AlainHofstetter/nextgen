public interface IPermissionSetAssignmentMDT  extends fflib_ISObjectDomain  {
	void applyPermissionSets(fflib_ISObjectUnitOfWork uow, List<SObject> records, List<PermissionSetAssignment> userPerms);

}