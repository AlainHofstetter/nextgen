/*
*	@description General class for implementing summary fields.
	To use it, you have to extend this class and implement performCalculation method.
	This class will perform one SOQL request and one DML update.
*
*	@author akr, ach
*	@copyright PARX
*/
public abstract class CommonSummary
{
	protected List<ChildInfo> childInfoList;
	private String parentObjectName;
	protected List<String> parentFields;
	protected al.ConditionGroup parentConditions;
	private boolean isUseOldImplementation = false;
	
	protected CommonSummary(){}
	
	public CommonSummary(String theParent, List<String> theParentFields, al.ConditionGroup theParentConditions, List<ChildInfo> theChildInfoList)
	{
		this.parentObjectName = theParent;
		this.parentFields = theParentFields;
		if (this.parentFields == null)
		{
			this.parentFields = new List<String>{'Id'};
		}
		this.childInfoList = theChildInfoList;
		for(ChildInfo aChildInfo : this.childInfoList)
		{
			if (aChildInfo.childFields == null)
			{
				aChildInfo.childFields = new List<String>{'Id'};
			}
		}

		this.parentConditions = theParentConditions;
	}
	
	/**
	*	@DEPRECATED
	* Main constructor.
	* You have to set:
	* theParent - name of the parent object (that keeps summary fields).
	* theRelation - name of the relateionship from the parent to child object.
	* theParentFields - list of fields to get from parent object. They could be used in calcualtions afterwards.
	* theChildFields - list of fields to get from child object. They could be used in calcualtions afterwards.
	* theParentConditions - SOQL where conditions for Parent SOQL.
	* theParentConditions - SOQL where conditions for Child SOQL.
	*/
	public CommonSummary(String theParent, String theRelation, List<String> theParentFields, List<String> theChildFields,
		 al.ConditionGroup theParentConditions, al.ConditionGroup theChildConditions)
	{
		this(theParent, theParentFields, theParentConditions, 
				new List<ChildInfo>{new ChildInfo(theRelation, theChildFields, theChildConditions)});
		this.isUseOldImplementation = true;
	}
	
	/**
	*	@DEPRECATED
	* Constructor, that allows you to user Summary without any SOQL conditions.
	* You have to set:
	* theParent - name of the parent object (that keeps summary fields).
	* theRelation - name of the relateionship from the parent to child object.
	* theParentFields - list of fields to get from parent object. They could be used in calcualtions afterwards.
	* theChildFields - list of fields to get from child object. They could be used in calcualtions afterwards.
	*/
	public CommonSummary(String theParent, String theRelation, List<String> theParentFields, List<String> theChildFields)
	{
		this(theParent, theRelation, theParentFields, theChildFields, null, null);
	}
	
	/**
	* Method, that should be implemented to use the class.
	* This method should performa the main calculation.
	* It gets parent sObject and all the child sObjects, that are related to this parent and follows the conditions.
	* You have to return the modified parent object.
	*/
	protected virtual sObject performCalculation(sObject theParent, List<sObject> theChildList)
	{
		return null;
	}
	
	/**
	* This method should performa the main calculation.
	* It gets parent sObject and all the child sObjects, that are related to this parent and follows the conditions.
	* You have to return the modified parent object. 
	*	@param theChildMap: RelationName => List of childs
	*/
	protected virtual sObject performCalculation(sObject theParent, Map<String, List<sObject>> theChildMap)
	{
		return null;
	}
	
	/**
	* You should run this method to activate the main process.
	* It generates SOQL request, performs it and sends results to performCalculation method one by one.
	* Afterwards it updates modified parent objects.
	* 
	* You have to put list of IDs for parent object to update.
	*/
	public virtual void updateObjects(Set<Id> theParentSet)
	{
		if (theParentSet == null || theParentSet.size() == 0)
		{
			return;
		}
		String aQuery = generateQuery(theParentSet);
		List<sObject> aResult = Database.query(aQuery);
		System.debug('***Result' + aResult);
		List<sObject> aListToUpdate = new List<sObject>();
		for (sObject aParent: aResult)
		{
			sObject aNewParent;
			if (!this.isUseOldImplementation)
			{
				Map<String, List<sObject>> aChildrenMap = new Map<String, List<sObject>>();
				for(ChildInfo aChildInfo : this.childInfoList)
				{
					List<sObject> aChildren = aParent.getSObjects(aChildInfo.relation);
					aChildren = aChildren == null ? new List<sObject>() : aChildren;
					aChildrenMap.put(aChildInfo.relation, aChildren);
				}
				aNewParent = performCalculation(aParent, aChildrenMap);
			} else
			{
				List<sObject> aChildren = aParent.getSObjects(this.childInfoList.get(0).relation);
				aChildren = aChildren == null ? new List<sObject>() : aChildren;
				aNewParent = performCalculation(aParent, aChildren);
			}
			if (aNewParent != null)
			{
				aListToUpdate.add(aNewParent);
			}
		}
		update aListToUpdate;
	}
	
	/**
	*	@description update opbjects without commit.
	*/
	public void updateObjectsWithoutCommit(List<sObject> theParentList)
	{
		if (theParentList == null || theParentList.size() == 0)
		{
			return;
		}
		Map<Id, sObject> aParentMap = new Map<Id, sObject>();
		for (sObject aParentObj: theParentList)
		{
			if (aParentObj.Id != null)
			{
				aParentMap.put(aParentObj.Id, aParentObj);
			}
		}
		String aQuery = generateQuery(aParentMap.keySet());
		List<sObject> aResult = Database.query(aQuery);
		System.debug('***Result' + aResult);
		List<sObject> aListToUpdate = new List<sObject>();
		for (sObject aParent: aResult)
		{
			if (this.childInfoList.size() > 0)
			{
				Map<String, List<sObject>> aChildrenMap = new Map<String, List<sObject>>();
				for(ChildInfo aChildInfo : this.childInfoList)
				{
					List<sObject> aChildren = aParent.getSObjects(aChildInfo.relation);
					aChildren = aChildren == null ? new List<sObject>() : aChildren;
					aChildrenMap.put(aChildInfo.relation, aChildren);
				}
				performCalculation(aParent, aChildrenMap);
			} else
			{
				List<sObject> aChildren = aParent.getSObjects(this.childInfoList.get(0).relation);
				aChildren = aChildren == null ? new List<sObject>() : aChildren;
				performCalculation(aParentMap.get(aParent.Id), aChildren);
			}
		}
	}
	
	/**
	*	@descriptionGenerates subquery to get child objects.
	*/
	private String generateSubQuery(ChildInfo theChildInfo)
	{
		al.SoqlBuilder aSubQuery = new al.SoqlBuilder();
		aSubQuery.selectx(theChildInfo.childFields).fromx(theChildInfo.relation);
		if (theChildInfo.childConditions != null)
		{
			aSubQuery.wherex(theChildInfo.childConditions);
		}
		return aSubQuery.toSOQL();
	}
	
	/**
	*	@descriptionGenerates query to get parent and child objects.
	*/
	private String generateQuery(Set<Id> theParentSet)
	{
		List<String> aTotalFields = new List<String>();
		aTotalFields.addAll(parentFields);
		for(ChildInfo aChildInfo : this.childInfoList)
		{
			aTotalFields.add('(' + generateSubQuery(aChildInfo) +')');
		}
		
		List<Id> aParentList = new List<Id>();
		aParentList.addAll(theParentSet);

		al.SoqlBuilder aQuery = new al.SoqlBuilder();
		al.AndCondition aConditions = new al.AndCondition();
		aConditions.add(new al.SetCondition('Id', al.Operator.INX, aParentList));
		if (parentConditions != null)
		{
			aConditions.add(parentConditions);
		}
		aQuery.selectx(aTotalFields).fromx(parentObjectName).wherex(aConditions);
		String aResSQOL = aQuery.toSOQL();
		System.debug('*** Query: ' + aResSQOL);
		return aResSQOL; 
	}
	
	/*
	*	@description child information for commonSummary class.
	*
	*	@author ach
	*	@copyright PARX
	*/
	public with sharing class ChildInfo
	{
		public String relation { get; set; }
		public List<String> childFields { get; set; }
		public al.ConditionGroup childConditions { get; set; }
		
		public ChildInfo(String theRelation, List<String> theChildFields, al.ConditionGroup theChildConditions)
		{
			this.relation = theRelation;
			this.childFields = theChildFields;
			this.childConditions = theChildConditions;
		}
		
			public ChildInfo(String theRelation, List<String> theChildFields)
		{
			this(theRelation, theChildFields, null);
		}
	}
}