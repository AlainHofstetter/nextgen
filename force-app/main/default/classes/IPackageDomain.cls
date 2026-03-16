public interface IPackageDomain extends fflib_ISObjectDomain {

  void save(fflib_ISObjectUnitOfWork uow);

  void del(fflib_ISObjectUnitOfWork uow);

}