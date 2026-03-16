global class UtilityLoadSandboxData implements SandboxPostCopy {
  global void runApexClass(SandboxContext context) {
		
		//System.debug('Hello Sandbox data ' + context.organizationId() + ' ' + context.sandboxId() + context.sandboxName());

		// planning code only -- create private method for dynamic load using headers of files to get column list 
		// and s.Name to be SObject and order

		//example  - account

		StaticResource defaultResource = [Select s.Body From StaticResource s where s.Name LIKE 'Sandbox_1_Account'];

		blob tempB = defaultResource.Body;
		String contentFile = tempB.toString();
		String[] filelines = contentFile.split('\n');

		// harvest columns to build field list for loading

		//List<object_to_Create__c> defaults = new List<object_to_Create__c>();

		//for (Integer i=1;i<filelines.size();i++)
		//{
		//	object_to_Create__c temp = object_to_Create__c();
		//	String[] inputvalues = filelines[i].split(',');
			
		//	//temp.Field1__c = inputValues[0];
		//	//temp.Field2__c = inputValues[1];
			
		//	defaults.add(temp);	
		//}

		//insert defaults;

		// possibly use LoadData if Parx notes no trigger action on load (question posed)
    }

    // notes and urls
    // https://docs.releasenotes.salesforce.com/en-us/spring16/release-notes/rn_deployment_sandbox_postcopy_script.htm

    // describeSObjects --> https://developer.salesforce.com/docs/atlas.en-us.api.meta/api/sforce_api_calls_describesobjects.htm

    // http://salesforce.stackexchange.com/questions/273/copy-production-data-to-developer-sandbox --> python-based answer

    // ff --> https://developer.financialforce.com/customizations/importing-large-csv-files-via-batch-apex/

    



  }