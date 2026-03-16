public interface IPurchasingSelector extends fflib_ISObjectSelector {

  List<Purchasing__c> byBillerAccountProjectNr(Set<String> billerAccountProjNrs);

}