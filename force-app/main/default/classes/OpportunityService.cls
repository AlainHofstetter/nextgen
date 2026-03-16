/*
*	@description Opportunity service.
*
*	@author ach
*	@copyright PARX
*/
public with sharing class OpportunityService
{
	/**
	*	Update forecasts related to the opportunities.
	*/
	public static void updateForecasts(List<Opportunity> theOpportunities)
	{
		// delete existing forecasts
		delete [SELECT Id FROM ResourceForecast__c WHERE Opportunity__c IN : new Map<Id, Opportunity>(theOpportunities).keySet()];
		
		List<ResourceForecast__c> aForecasts = new List<ResourceForecast__c>();
		//generate new ones
		for (Opportunity anOpportunity : theOpportunities)
		{
			//'Amount', 'Probability', 'ProjectStart__c', 'ProjectEnd__c', 'DailyRate__c'
			if (anOpportunity.Amount != null && anOpportunity.Probability != null && anOpportunity.ProjectStart__c != null && 
					anOpportunity.ProjectEnd__c != null)
			{
				aForecasts.addAll(generateForecasts(anOpportunity));
			}
		}
		insert aForecasts;
	}
	
	/**
	*	Generate the forecasts for opportunity.
	*/
	private static List<ResourceForecast__c> generateForecasts(Opportunity theOpportunity)
	{
		List<ResourceForecast__c> aResult = new List<ResourceForecast__c>();
		Date anIterationDate = theOpportunity.ProjectStart__c;
		
		//Number of all days
		Integer projectDuration = theOpportunity.ProjectStart__c.daysBetween(theOpportunity.ProjectEnd__c)+1;
		system.debug('### projectDuration:' + projectDuration);
		//last day of the last month
		Date anEndOfPeriod = getLastDayInMonth(theOpportunity.ProjectEnd__c);
		
		//generate forecasts for all month in our period.
		while(anIterationDate <= anEndOfPeriod)
		{
			ResourceForecast__c aForecast = new ResourceForecast__c(Opportunity__c = theOpportunity.Id, 
					CurrencyIsoCode = theOpportunity.CurrencyIsoCode);
			
			Date aLastForecastDayInMonth = getLastDayInMonth(anIterationDate);
			// if we are in the last month of our period - we should use the ProjectEnd__c instead of calendar last day
			if (theOpportunity.ProjectEnd__c.monthsBetween(anIterationDate) == 0)
			{
				aLastForecastDayInMonth = theOpportunity.ProjectEnd__c;
			}
			system.debug('### aLastForecastDayInMonth:' + aLastForecastDayInMonth);
			Integer numberOfForecastDaysInMonth = anIterationDate.daysBetween(aLastForecastDayInMonth)+1;
			system.debug('### numberOfForecastDaysInMonth:' + numberOfForecastDaysInMonth);
			aForecast.Amount__c = (theOpportunity.Amount * numberOfForecastDaysInMonth / projectDuration).setScale(2);
			system.debug('### Amount__c:' + aForecast.Amount__c);
			aForecast.DateFirstDayOfMonth__c = anIterationDate.toStartOfMonth();
			if (theOpportunity.DailyRate__c != null && theOpportunity.DailyRate__c != 0)
			{
				aForecast.Days__c = aForecast.Amount__c / theOpportunity.DailyRate__c;
				aForecast.ExpectedDays__c = (theOpportunity.Probability * aForecast.Days__c / 100).setScale(2);
			}
			aForecast.ExpectedRevenue__c = (theOpportunity.Probability * aForecast.Amount__c/ 100).setScale(2);
			
			aResult.add(aForecast);
			//go to the nextMonth
			anIterationDate = getLastDayInMonth(aLastForecastDayInMonth).addDays(1);
		}
		
		return aResult;
	}
	
	/**
	*	Get the last day of the month.
	*/
	private static Date getLastDayInMonth(Date theDate)
	{
		Integer numberOfDays = Date.daysInMonth(theDate.year(), theDate.month());
		return Date.newInstance(theDate.year(), theDate.month(), numberOfDays);
	}
}