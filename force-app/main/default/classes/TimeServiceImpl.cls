public with sharing class TimeServiceImpl implements ITimeService {

  public void save(List<Time__c> times) {
    fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
    ITimeDomain domain = TimeDomain.newInstance(times);
    domain.save(uow);
    uow.commitWork();
  }
}