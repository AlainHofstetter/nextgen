public with sharing class ExpenseService {

  private static IExpenseService service() {
    return (IExpenseService) Application.Service.newInstance(IExpenseService.class);
  }

  public static void save(List<Expense__c> expenses) {
    service().save(expenses);
  }

}