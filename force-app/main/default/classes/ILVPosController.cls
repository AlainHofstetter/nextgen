public with sharing class ILVPosController {

  @AuraEnabled
  public static ILVCreation get(Id projectId, String dateFrom, String dateTo) {
    return ILVPosService.get(projectId, dateFrom, dateTo);
  }

  @AuraEnabled
  public static void save(Invoice__c draft, List<ILVPos__c> positions) {
	  List<ILVPos__c> auxPositions = new List<ILVPos__c>();
    auxPositions.addAll(positions);
    ILVPosService.save(draft, auxPositions);
  }

  @AuraEnabled
  public static Id getILVRecordTypeId() {
    return Utils.getRecordTypeIdByDevName('Invoice__c', 'ILV');
  }

	@AuraEnabled
	public static Id startQueueableJob(Invoice__c draft, List<ILVPos__c> positions) {

		System.debug('---ILVPosController.startQueueableJob--- draft: '+draft);
		System.debug('---ILVPosController.startQueueableJob--- positions: '+positions);

		User userSettings = [Select IsFinanceManager__c, PS480FunctionValidationRulesActive__c  From User Where Id = :UserInfo.getUserId()];

		if (Test.isRunningTest()) {
			userSettings.IsFinanceManager__c = false;
			userSettings.PS480FunctionValidationRulesActive__c = true;
		}

		// Perform some validations here so that they can be reported back to the user by the Lightning component.
		// The validations performed by Validation Rules are not reported back because the insert/update operations
		// are performed from a Future method.
		String errMsg;
		errMsg = InvoiceController.validateInvoice(draft, userSettings, 'ILV');

		System.debug('---ILVPosController.startQueueableJob--- errMsg: '+errMsg);

		if (String.isEmpty(errMsg)) {
			errMsg = validateILVPosition(positions, userSettings);
		}

		if (String.isNotEmpty(errMsg)) {
			System.debug('---ILVPosController.startQueueableJob--- Throw error: '+errMsg);
			throw new AuraHandledException(errMsg);  
		}
		else {
			ILVQueueable queueableJob = new ILVQueueable(draft, positions);

			Id jobId = System.enqueueJob(queueableJob);
			return jobId;
		}
	}

	@AuraEnabled
	public static Boolean checkIsJobFinished(Id jobId) {
		System.debug('---ILVPosController.checkIsJobFinished--- jobId: '+jobId);
		Boolean isFinished = false;

		List<AsyncApexJob> jobInfo = [SELECT Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :jobId];
		if (jobInfo.isEmpty() || jobInfo[0].Status == 'Aborted' || jobInfo[0].Status == 'Completed' || jobInfo[0].Status == 'Failed') {
			isFinished = true;
		}

		return isFinished;
	}

	/**
	 * Validates ILVPos records
	 */
	private static String validateILVPosition(List<ILVPos__c> positions, User userSettings) {

		if (userSettings.PS480FunctionValidationRulesActive__c && !userSettings.IsFinanceManager__c) {
			Set<Id> posPkgIDs = new Set<Id>();
			Set<String> types = new Set<String>();
			for (ILVPos__c invPos : positions) {
				posPkgIDs.add(invPos.PackageName__c);
			}

			System.debug('---ILVPosController.validateILVPosition--- posPkgIDs: '+posPkgIDs);

			Map<Id, Package__c> posPkg = new Map<Id, Package__c>([SELECT Id, PackageSuperior__c, RecordType.DeveloperName, 
																		 ProjectName__r.ProjectCostCenter__r.Name, PackageType__c,
																		 PackageType2__c
																  FROM   Package__c WHERE Id IN :posPkgIDs]);

			System.debug('---ILVPosController.validateILVPosition--- ILVType__c : '+posPkg);
			for (ILVPos__c invPos : positions) {
				System.debug('---ILVPosController.validateILVPosition--- posPkgIDs: '+invPos);
				Package__c pkg = posPkg.get(invPos.PackageName__c);
				if (pkg == null) continue;

				if (invPos.ILVType__c != pkg.RecordType.DeveloperName) {
					return 'The invoice position Package Type Name does not match the Package Record Type Name.' +
						   'Please get in touch with your Super User. [ILVPosController ILV003]';
				}
		
			}
		}

		return '';
	}
}