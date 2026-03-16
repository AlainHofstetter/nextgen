public interface IOpportunitySelector  extends fflib_ISObjectSelector {
	List<Opportunity> selectWithProducts(Set<Id> ids);
}