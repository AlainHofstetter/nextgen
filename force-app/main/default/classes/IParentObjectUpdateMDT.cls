public interface IParentObjectUpdateMDT extends fflib_ISObjectDomain {

  void go(fflib_ISObjectUnitOfWork uow, List<SObject> children, Map<Id, SObject> oldChildren);

}