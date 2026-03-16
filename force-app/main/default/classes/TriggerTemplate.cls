/*
*	@description Class contains some useful methods and classes to implement trigger functionality.
	
	To use this templeate, you should create trigger that handles all the possible trigger actions.
	Then in trigger body, you should create TriggerManager.
	You can add handlers (Handler interface) to this manager with actions to be handled (use method addHandler).
	
	After preparing the manager, you should call runHandlers() method.
	This method will call only handlers related to this action.
*	
*	@author akr
*	@copyright PARX
*/
global without sharing class TriggerTemplate
{
	/**
	*	@description Type of the trigger action.
	*/
	public enum TriggerAction
	{
		afterdelete, afterinsert, afterundelete,
		afterupdate, beforedelete, beforeinsert, beforeupdate
	}
	
	/**
	*	@description Main interface to implement by trigger handler.
	*/
	public interface Handler
	{
		/**
			Method that should be implemented in trigger handler.
			Action as trigger action type.
		*/
		void handle(TriggerTemplate.TriggerAction theAction);
		
		/**
			This should be implemented in trigger handler.
			It should set new values and old values as class variables.
		*/
		void setValues(List<sObject> theNewValues, Map<Id, sObject> theOldValues);
		
	}

	/**
	*	@description Main trigger dispatcher.
		It accumulates handlers and keep them in dependence of action types.
		On runHandlers() run it calls only correct handlers.
	*/
	public class TriggerManager
	{
		/**
		*	@description Keeps handlers with action type.
		*/
		private Map<String, List<Handler>> eventHandlerMapping = new Map<String, List<Handler>>();
		
		/**
		*	@description Add handler with one action type.
		*/
		public void addHandler(Handler theHandler, TriggerTemplate.TriggerAction theAction)
		{
			List<Handler> aHandlers = eventHandlerMapping.get(theAction.name());
			if (aHandlers == null)
			{
				aHandlers = new List<Handler>();
				eventHandlerMapping.put(theAction.name(), aHandlers);
			}
			aHandlers.add(theHandler);
		}
	
		/**
		*	@description Add handler to list of action type.
		*/
		public void addHandler(Handler theHandler, List<TriggerTemplate.TriggerAction> theActions)
		{
			for (TriggerAction anAction: theActions)
			{
				addHandler(theHandler, anAction);
			}
		}
		
		/**
		*	@description Runs handlers that corresponds to the action.
		*/
		public void runHandlers()
		{
			TriggerAction theAction = null;
			if( Trigger.isBefore)
			{
				if (Trigger.isInsert)
				{
					theAction = TriggerTemplate.TriggerAction.beforeinsert;
				} else if (Trigger.isUpdate)
				{
					theAction = TriggerTemplate.TriggerAction.beforeupdate;
				} else if (Trigger.isDelete)
				{
					theAction = TriggerTemplate.TriggerAction.beforedelete;
				}
			} else if (Trigger.isAfter)
			{
				if (Trigger.isInsert)
				{
					theAction = TriggerTemplate.TriggerAction.afterinsert;
				} else if (Trigger.isUpdate)
				{
					theAction = TriggerTemplate.TriggerAction.afterupdate;
				} else if (Trigger.isDelete)
				{
					theAction = TriggerTemplate.TriggerAction.afterdelete;
				} else if (Trigger.isUnDelete)
				{
					theAction = TriggerTemplate.TriggerAction.afterundelete;
				}
			}
			
			List<Handler> aHandlers = eventHandlerMapping.get(theAction.name());
			if (aHandlers != null && !aHandlers.isEmpty())
			{
				for (Handler aHandler : aHandlers)
				{
					aHandler.setValues(Trigger.new, Trigger.oldMap);
					aHandler.handle(theAction);
				}
			}
		}
	}
}