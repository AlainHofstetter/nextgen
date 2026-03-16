public with sharing class DatedConversionRateSelector extends fflib_SObjectSelector implements IDatedConversionRateSelector {

  private static XRatesCached allXratesCached;  // Cached if all the exchange rates.

  public static IDatedConversionRateSelector newInstance() {
    return (IDatedConversionRateSelector) Application.Selector.newInstance(DatedConversionRate.SObjectType);
  }

  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField> {
      DatedConversionRate.ConversionRate,
      DatedConversionRate.IsoCode,
      DatedConversionRate.NextStartDate,
      DatedConversionRate.StartDate
    };
  }

  public Schema.SObjectType getSObjectType() {
    return DatedConversionRate.sObjectType;
  }

  public List<DatedConversionRate> selectByISOCodeAndDate(String isoCode, Date dateoOfRate){
    System.debug('---DatedConversionRateSelector.selectAll--- isoCode: '+isoCode+' dateoOfRate: '+dateoOfRate);

    fflib_QueryFactory query = newQueryFactory();
    query.setCondition('IsoCode = :isoCode AND StartDate <= :dateoOfRate AND NextStartDate > :dateoOfRate');
    System.debug('---DatedConversionRateSelector.selectAll--- query: '+query.toSOQL());
    return (List<DatedConversionRate>) Database.query(query.toSOQL());
  }

  public List<DatedConversionRate> selectByDate(Date dateoOfRate){
    fflib_QueryFactory query = newQueryFactory();
    query.setCondition('StartDate <= :dateoOfRate AND NextStartDate > :dateoOfRate');
    return (List<DatedConversionRate>) Database.query(query.toSOQL());
  }

  public List<DatedConversionRate> selectByISOCode(String isoCode){
    fflib_QueryFactory query = newQueryFactory();
    query.setCondition('IsoCode = :isoCode');
    return (List<DatedConversionRate>) Database.query(query.toSOQL());
  }

  /**
   * @Define:  Retrieves all exchange rates, ordered from the most recent to the earliest.
   * 
   *           The results are cached to prevent repeated SELECT queries within the same transaction on the same day.
   *           A fresh query is performed only if the rates haven't been retrieved yet or if the cached data is from a previous day.
   */
  public List<DatedConversionRate> selectAll(){

    System.debug('---DatedConversionRateSelector.selectAll--- allXratesCached: '+(allXratesCached == null || allXratesCached.renew()));
    
    if (allXratesCached == null || allXratesCached.renew()) {
      fflib_QueryFactory query = newQueryFactory();
      query.setCondition('StartDate = LAST_N_DAYS:366');
      System.debug('---DatedConversionRateSelector.selectAll--- query: '+query);

      allXratesCached = new XRatesCached();
      allXratesCached.xrates = (List<DatedConversionRate>) Database.query(query.toSOQL());
    }

    return allXratesCached.xrates;
  }

  /**
   * @Define  Class to cached exchange rates
   */
  Private class XRatesCached {
    Date                      xratesDate;
    List<DatedConversionRate> xrates;

    XRatesCached() {
      xratesDate = Date.today();
    }

    public Boolean renew() {
      if (allXratesCached.xrates == null || allXratesCached.xrates.isEmpty() || allXratesCached.xratesDate < Date.today()) {
        return true;
      }
      else {
        return false;
      }
    }
  }

 
  
}