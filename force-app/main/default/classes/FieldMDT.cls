/**
 * Domain layer for working with Field__mdt custom metadata and applying
 * metadata-driven behaviors to arbitrary SObjects.
 *
 * Responsibilities
 * - Construct a domain instance for Field__mdt records (fflib domain pattern).
 * - Prevent deletion of SObjects when specific metadata-driven boolean flags are set.
 * - Maintain exchange-rate fields (to CHF and optionally to other cross currencies
 *   such as SGD/GBP) based on a date + ISO currency on the target records.
 *
 * Key Concepts
 * - This class expects a set of Field__mdt metadata rows that define:
 *   • Which SObject fields hold the exchange-rate date and ISO currency.
 *   • Which SObject fields should store computed exchange rates (to CHF and optionally others).
 *   • Which boolean fields gate deletions and the error message to use.
 * - Currency conversion is driven by DatedConversionRate records (via DatedConversionRateSelector).
 *   The method inverts the stored ConversionRate (1 / ConversionRate) to derive target→CHF.
 *
 * Dependencies
 * - fflib_SObjectDomain (Apex Enterprise Patterns)
 * - IFieldMDT (domain interface implemented by this class)
 * - FieldMDTConst (constants for CurrencyManagementFieldType__c keys)
 * - DatedConversionRateSelector (selector for currency rates)
 *
 */
public with sharing class FieldMDT  extends fflib_SObjectDomain implements IFieldMDT {

  /**
   * Factory method used by Application.Domain to build this domain.
   *
   * @param records List of Field__mdt rows to back this domain instance.
   * @return IFieldMDT domain instance.
   */
  public static IFieldMDT newInstance(List<Field__mdt> records) {
    return (IFieldMDT) Application.Domain.newInstance(records);
  }

  /**
   * Standard constructor used by the fflib domain base class.
   *
   * @param records List of Field__mdt rows to back this domain instance.
   */
  public FieldMDT(List<Field__mdt> records) {
    super(records);
  }

  /**
   * fflib constructable wrapper so Application.Domain can instantiate this domain.
   */
  public class Constructor implements fflib_SObjectDomain.IConstructable {
    /**
     * Create a new FieldMDT domain instance.
     *
     * @param sObjectList A list of Field__mdt records (typed as SObject by the framework).
     * @return A new FieldMDT domain instance.
     */
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new FieldMDT(sObjectList);
    }
  }

  /**
   * Prevents deletion of SObjects when any metadata-defined boolean field on the SObject is TRUE.
   *
   * For each SObject in {@code recordsToCheck}, the method iterates the backing Field__mdt rows
   * and evaluates the SObject field named by {@code APIName__c}. If the field is a boolean and
   * is TRUE, an error is added to the SObject using {@code DeletionErrorMessage__c}.
   *
   * Intended usage: call from a before delete trigger or domain delete handler.
   *
   * @param recordsToCheck The SObjects being deleted (typed as SObject for reusability).
   *
   * @example
   *  @TestVisible
   *  void example_deleteGuard() {
   *    List<SObject> victims = new List<SObject>{ someRecord__c };
   *    FieldMDT domain = new FieldMDT([SELECT APIName__c, DeletionErrorMessage__c FROM Field__mdt]);
   *    domain.controlDeletion(victims); // adds addError(...) if configured flags are true
   *  }
   */
  @TestVisible
  public void controlDeletion(List<SObject> recordsToCheck){
    for(SObject obj : recordsToCheck){
      for(Field__mdt f: (List<Field__mdt>) records){
        if((Boolean)obj.get(f.APIName__c) == true){
          obj.addError(f.DeletionErrorMessage__c);
        }
      }
    }
  }

  /**
   * Updates exchange-rate fields (to CHF and optionally to SGD/GBP) on the provided SObjects.
   *
   * Behavior
   * - Compares each new record with its old version (if provided). If either the configured
   *   date field or the currency field changed—or if the record is new—it recomputes rates.
   * - CHF rate: computed as (1 / ConversionRate) using the DatedConversionRate that matches
   *   the record’s ISO code and date (where StartDate ≤ date < NextStartDate).
   * - Optional cross rates (e.g., to SGD/GBP): computed via cross-rate
   *   (objCcy→CHF) / (xCcy→CHF).
   *
   * Metadata Required (by CurrencyManagementFieldType__c):
   * - FieldMDTConst.EXCHANGE_RATE_DATE_FIELD       → APIName__c of the date field
   * - FieldMDTConst.CURRENCY_FIELD                 → APIName__c of the ISO code field
   * - FieldMDTConst.EXCHANGE_RATE_TO_CHF_FIELD     → APIName__c of the target CHF field
   * - (Optional) FieldMDTConst.EXCHANGE_RATE_TO_SGD_FIELD → APIName__c of SGD cross-rate field
   * - (Optional) FieldMDTConst.EXCHANGE_RATE_TO_GBP_FIELD → APIName__c of GBP cross-rate field
   *
   * @param newRecords The current versions of SObjects being inserted/updated.
   * @param oldRecords A map of prior versions keyed by Id (can be null; treated as empty).
   *
   * @example
   *  // Typically invoked in before insert/before update:
   *  FieldMDT fmdt = new FieldMDT([SELECT CurrencyManagementFieldType__c, APIName__c FROM Field__mdt]);
   *  fmdt.updateExchangeRate(Trigger.new, Trigger.isInsert ? null : Trigger.oldMap);
   */
   public void updateExchangeRate(List<SObject> newRecords, Map<Id,SObject> oldRecords){
    // production path preserves behavior
    List<DatedConversionRate> rates = DatedConversionRateSelector.newInstance().selectAll();
    updateExchangeRate(newRecords, oldRecords, rates);
  }

  /**
   * 
   */
  public void updateExchangeRate(List<SObject> newRecords, Map<Id,SObject> oldRecords, List<DatedConversionRate> rates) {

    System.debug('---FieldMDT.updateExchangeRate--- newRecords: '+newRecords);

    if (oldRecords == null) {
      oldRecords = new Map<Id, SObject>();
    }

    if (rates == null) {
      rates = new List<DatedConversionRate>();
    }

    System.debug('---FieldMDT.updateExchangeRate--- records: '+records);

    // Build a map of metadata entries keyed by CurrencyManagementFieldType__c
    Map<String,Field__mdt> fieldMap = new Map<String,Field__mdt>();
    for(Field__mdt  f : (List<Field__mdt>) records){
      fieldMap.put(f.CurrencyManagementFieldType__c, f);   
    }

    // Exit if required metadata is missing
    if (fieldMap.isEmpty()) {
      return;
    }

    // Get SObject field API names from metadata
    String dateField = fieldMap.get(FieldMDTConst.EXCHANGE_RATE_DATE_FIELD).APIName__c;
    String currencyField = fieldMap.get(FieldMDTConst.CURRENCY_FIELD).APIName__c;
    String exchangeRateField = fieldMap.get(FieldMDTConst.EXCHANGE_RATE_TO_CHF_FIELD).APIName__c;

    // Optional cross-rate fields: SGD & GBP
    String exchangeRateSGDField = fieldMap.containsKey(FieldMDTConst.EXCHANGE_RATE_TO_SGD_FIELD) ? fieldMap.get(FieldMDTConst.EXCHANGE_RATE_TO_SGD_FIELD).APIName__c : null;
    String exchangeRateGBPField = fieldMap.containsKey(FieldMDTConst.EXCHANGE_RATE_TO_GBP_FIELD) ? fieldMap.get(FieldMDTConst.EXCHANGE_RATE_TO_GBP_FIELD).APIName__c : null;
    

    // Pull all exchange rates once
    // List<DatedConversionRate> rates = DatedConversionRateSelector.newInstance().selectAll();

    for (SObject obj: newRecords) {
      SObject oldObj = oldRecords.get(obj.Id);

      // Recompute exchange rates only when new, or when date/currency changed
      if (oldObj == null || (obj.get(dateField) != oldObj.get(dateField) || obj.get(currencyField) != oldObj.get(currencyField))) {
        // Calculate and set exchange rate to CHF
        obj.put(exchangeRateField, getExchangeRate(rates, (Date)obj.get(dateField), (String)obj.get(currencyField)));

        // If SGD cross-rate field is configured, compute it from objCcy→CHF / SGD→CHF
        if (String.isNotBlank(exchangeRateSGDField)) {
          Decimal xrateToSGD = calculateCrossRate(rates, 'SGD', (Date)obj.get(dateField), (Decimal) obj.get(exchangeRateField));
          obj.put(exchangeRateSGDField, xrateToSGD);
        }

        // If GBP cross-rate field is configured, compute it from objCcy→CHF / GBP→CHF
        if (String.isNotBlank(exchangeRateGBPField)) {
          Decimal xrateToGBP = calculateCrossRate(rates, 'GBP', (Date)obj.get(dateField), (Decimal) obj.get(exchangeRateField));
          obj.put(exchangeRateGBPField, xrateToGBP);
        }
      }
    }
  }

  /**
   * Calculates a cross-rate from the record’s currency to {@code xCcy} using CHF as the pivot:
   * (objCcy→CHF) / (xCcy→CHF).
   *
   * @param rates               DatedConversionRate rows (pre-fetched).
   * @param xCcy                ISO code of cross currency (e.g., 'SGD', 'GBP').
   * @param xrateDate           The date to evaluate rates on.
   * @param xrateObjCcyToCHF    The already-computed objCcy→CHF rate for the record.
   * @return The cross-rate objCcy→xCcy; returns 0 if xCcy→CHF is 0 or not found.
   */
  private Decimal calculateCrossRate(List<DatedConversionRate> rates, String xCcy, Date xrateDate, Decimal xrateObjCcyToCHF) {
    // Get xCcy→CHF rate
    Decimal xrateXCcyToCHF = getExchangeRate(rates, xrateDate, xCcy);

    System.debug('---FieldMDT.calculateCrossRate--- xrateObjCcyToCHF: '+xrateObjCcyToCHF+' xrateCcyToCHF: '+xrateXCcyToCHF);

    // Cross-rate: (objCcy→CHF) / (xCcy→CHF)
    Decimal xrateToXCcy = xrateXCcyToCHF != 0 ? (xrateObjCcyToCHF / xrateXCcyToCHF) : 0;
    System.debug('---FieldMDT.calculateCrossRate--- xrateToXCcy: '+xrateToXCcy);
    return xrateToXCcy;
  }

  /**
   * Returns the rate target→CHF for the given ISO currency and date.
   *
   * Looks up the matching DatedConversionRate where:
   *  - r.IsoCode == isoCode
   *  - r.StartDate ≤ dateOfRate < r.NextStartDate
   *  - r.ConversionRate > 0
   *
   * The returned value is 1 / r.ConversionRate (i.e., the inverse of Salesforce’s stored rate),
   * with a special case of 1.0 for CHF itself.
   *
   * @param rates      DatedConversionRate rows (pre-fetched).
   * @param dateOfRate The effective date for the rate.
   * @param isoCode    The 3-letter ISO currency code (e.g., 'EUR', 'USD', 'CHF').
   * @return target→CHF rate as a Double (1.0 for CHF, 0.0 if not found/invalid).
   */
  @TestVisible
  private Decimal getExchangeRate(List<DatedConversionRate> rates, Date dateOfRate, String isoCode){
    Decimal exchangeRate = isoCode == 'CHF'?1:0;
    for(DatedConversionRate r : rates){
      if(r.IsoCode == isoCode && r.StartDate <= dateOfRate && r.NextStartDate > dateOfRate && r.ConversionRate > 0){
        exchangeRate = 1/r.ConversionRate;
        break;
      }
    }
    return exchangeRate;
  }
}