public with sharing class ExpenseServiceImpl implements IExpenseService {

  public void save(List<Expense__c> expenses) {
    fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
    IExpense domain = Expense.newInstance(expenses);
    domain.save(uow);
    uow.commitWork();
  }
}