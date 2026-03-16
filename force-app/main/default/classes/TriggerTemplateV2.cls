/**
 * TriggerTemplate version 2.0
 *
 * This TriggerTemplate prevents triggers from being chained and has to be used
 * for all apex triggers. For a description on its usage see TriggerTemplate.md
 *
 * Copyright (c) PARX
 * All rights reserved.
 * 
 */
public with sharing class TriggerTemplateV2 
{
	//
	// PUBLIC PROPERTIES
	//
	
	// Flag to disable all trigger handlers. Should be used in visualforce controllers
	public static Boolean allTriggersDisabled = false;

	// Two lists to keep a record of the invoced trigger handlers, for debugging etc.
	public static List<String> beforeHandlerInvocations = new List<String>();
	public static List<String> afterHandlerInvocations = new List<String>();
	
	//
	// PRIVATE PROPERTIES
	//

	// Flag to enable all triggers. Should only be used when setting up a unit test
	private static Boolean allTriggersEnabled = false;

	private static String enabledBeforeHandlerClassName = null;
	private static String enabledAfterHandlerClassName = null;
	private static String enabledTriggerEventName = null;

	private static final String INSERT_EVENT_NAME = 'insert';
	private static final String UPDATE_EVENT_NAME = 'update';
	private static final String DELETE_EVENT_NAME = 'delete';
	private static final String UNDELETE_EVENT_NAME = 'undelete';
	
	private static Boolean isInitialized = false;
	
	public static void setupUnitTest()
	{
		allTriggersEnabled = true;
	}

	public static void startUnitTest()
	{
		isInitialized = false;
		allTriggersEnabled = false;
	}
		
	public class TriggerManager 
	{
		private BeforeTriggerHandler beforeHandler;
		private AfterTriggerHandler afterHandler;

		private String beforeHandlerClassName;
		private String afterHandlerClassName;

		public TriggerManager(TriggerHandlerAdapter triggerHandlerAdapter)
		{
			this(triggerHandlerAdapter,triggerHandlerAdapter);
		}

		public TriggerManager(BeforeTriggerHandler beforeHandler, AfterTriggerHandler afterHandler)
		{
			this.beforeHandler = beforeHandler;
			this.afterHandler = afterHandler;
			this.beforeHandlerClassName = getClassName(beforeHandler);
			this.afterHandlerClassName = getClassName(afterHandler);

			if(!isInitialized)
			{
				enabledBeforeHandlerClassName = beforeHandlerClassName;
				enabledAfterHandlerClassName = afterHandlerClassName;
				
				beforeHandlerInvocations.clear();
				afterHandlerInvocations.clear();

				if(Trigger.isInsert) 
				{
					enabledTriggerEventName = INSERT_EVENT_NAME;
				} 
				else if(Trigger.isUpdate) 
				{
					enabledTriggerEventName = UPDATE_EVENT_NAME;
				}
				else if(Trigger.isDelete) 
				{
					enabledTriggerEventName = DELETE_EVENT_NAME;
				}
				else if(Trigger.isUndelete) 
				{
					enabledTriggerEventName = UNDELETE_EVENT_NAME;
				}

				isInitialized = true;
			}
		}

		public void runHandlers()
		{
			if(!allTriggersDisabled)
			{
				if (Trigger.isBefore && beforeHandler != null && (enabledBeforeHandlerClassName == beforeHandlerClassName || allTriggersEnabled))
				{
					if (Trigger.isInsert && (enabledTriggerEventName == INSERT_EVENT_NAME || allTriggersEnabled))
					{
						beforeHandlerInvocations.add(beforeHandlerClassName + '.onBeforeInsert');
						beforeHandler.onBeforeInsert(Trigger.new);
					} 
					else if (Trigger.isUpdate && (enabledTriggerEventName == UPDATE_EVENT_NAME || allTriggersEnabled))
					{
						beforeHandlerInvocations.add(beforeHandlerClassName + '.onBeforeUpdate');
						beforeHandler.onBeforeUpdate(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
					} 
					else if (Trigger.isDelete && (enabledTriggerEventName == DELETE_EVENT_NAME || allTriggersEnabled))
					{
						beforeHandlerInvocations.add(beforeHandlerClassName + '.onBeforeDelete');
						beforeHandler.onBeforeDelete(Trigger.old, Trigger.oldMap);
					}
				} 
				else if (Trigger.isAfter && afterHandler != null && (enabledAfterHandlerClassName == afterHandlerClassName || allTriggersEnabled))
				{
					if (Trigger.isInsert && (enabledTriggerEventName == INSERT_EVENT_NAME || allTriggersEnabled))
					{
						afterHandlerInvocations.add(afterHandlerClassName + '.onAfterInsert');
						afterHandler.onAfterInsert(Trigger.new, Trigger.newMap);
					} 
					else if (Trigger.isUpdate && (enabledTriggerEventName == UPDATE_EVENT_NAME || allTriggersEnabled))
					{
						afterHandlerInvocations.add(afterHandlerClassName + '.onAfterUpdate');
						afterHandler.onAfterUpdate(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
					}
					else if (Trigger.isDelete && (enabledTriggerEventName == DELETE_EVENT_NAME || allTriggersEnabled))
					{
						afterHandlerInvocations.add(afterHandlerClassName + '.onAfterDelete');
						afterHandler.onAfterDelete(Trigger.old, Trigger.oldMap);
					} 
					else if (Trigger.isUndelete && (enabledTriggerEventName == UNDELETE_EVENT_NAME || allTriggersEnabled))
					{
						afterHandlerInvocations.add(afterHandlerClassName + '.onAfterUndelete');
						afterHandler.onAfterUndelete(Trigger.new, Trigger.newMap);
					}
				}
			}
		}

		/**
		 * Helper method to get the class name for a given Object
		 * Used as the key identifier of the trigger handler classes
		 */
		private String getClassName(Object o)
		{
			String className = null;
			if(o != null)
			{
				// The value looks something like this: "ProjectTriggerHandler:[idToOldProjectMap=null, newProjectList=null]"
				String objectAsString = String.valueOf(o);		
				className = objectAsString.substring(0,objectAsString.indexOf(':'));
			}
			return className;
		}
	}

	/**
	 * Interface definitions for the before and after trigger handlers
	 * 
	 */
	
	public interface BeforeTriggerHandler
	{
		void onBeforeInsert (List<sObject> newList);
		
		void onBeforeUpdate (List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap);
		
		void onBeforeDelete (List<sObject> oldList, Map<Id, sObject> oldMap);
	}

	public interface AfterTriggerHandler
	{
		void onAfterInsert (List<sObject> newList, Map<Id, sObject> newMap);
	
		void onAfterUpdate (List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap);
		
		void onAfterDelete (List<sObject> oldList, Map<Id, sObject> oldMap);

		void onAfterUndelete (List<sObject> newList, Map<Id, sObject> newMap);
	}

	/**
	 * An abstract adapter class that can be extended for convenience. By extending
	 * this class only the relevant handler methods need to be implemented.
	 */
	
	public abstract class TriggerHandlerAdapter implements BeforeTriggerHandler, AfterTriggerHandler
	{
		public virtual void onBeforeInsert (List<sObject> newList) {}
		
		public virtual void onBeforeUpdate (List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {}
		
		public virtual void onBeforeDelete (List<sObject> oldList, Map<Id, sObject> oldMap) {}

		public virtual void onAfterInsert (List<sObject> newList, Map<Id, sObject> newMap) {}
		
		public virtual void onAfterUpdate (List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {}
		
		public virtual void onAfterDelete (List<sObject> oldList, Map<Id, sObject> oldMap) {}
		
		public virtual void onAfterUndelete (List<sObject> newList, Map<Id, sObject> newMap) {}
	}
}