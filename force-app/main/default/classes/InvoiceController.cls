public with sharing class InvoiceController {

	@AuraEnabled
  	public static ProjectStructureBean getProjectStructure(Id projectId, String dateFrom, String dateTo) {
    	return InvoiceService.getProjectStructure(projectId, dateFrom, dateTo);
  	}

  	@AuraEnabled
  	public static void save(Invoice__c draft, List<Package__c> packages, List<InvoicePos__c> positions) {
    	
		System.debug('---InvoiceController.save--- draft: '+draft);
		System.debug('---InvoiceController.save--- packages: '+packages);
		System.debug('---InvoiceController.save--- positions: '+positions);

		User userSettings = [Select IsFinanceManager__c, PS480FunctionValidationRulesActive__c  From User Where Id = :UserInfo.getUserId()];

		if (Test.isRunningTest()) {
			userSettings.IsFinanceManager__c = false;
			userSettings.PS480FunctionValidationRulesActive__c = true;
		}

		System.debug('---InvoiceController.save--- userSettings: '+userSettings);

		// Perform some validations here so that they can be reported back to the user by the Lightning component.
		// The validations performed by Validation Rules are not reported back because the insert/update operations
		// are performed from a Future method.
		String errMsg;
		errMsg = validateInvoice(draft, userSettings, 'Billing');

		System.debug('---InvoiceController.save--- errMsg: '+errMsg);

		if (String.isEmpty(errMsg)) {
			errMsg = validateInvoicePosition(positions, userSettings);
		}

		if (String.isNotEmpty(errMsg)) {
			System.debug('---InvoiceController.save--- Throw error: '+errMsg);
			throw new AuraHandledException(errMsg);  
		}
		else {
			System.debug('---InvoiceController.save--- calling saveAsync');
			saveAsync(JSON.serialize(draft), JSON.serialize(packages), JSON.serialize(positions));
		}
  	}

	/**
	 * Prevent CPU time exceeded.
	 * @param draft : String 
	 * @param packages : String (List<Package__c> packages serialized)
	 * @param positions : String (List<InvoicePos__c> serialized)
	*/
	@future
	public static void saveAsync(String draft, String packages, String positions) {
		List<Package__c> auxPackages = (List<Package__c>) JSON.deserialize(packages, List<Package__c>.class);
    	List<InvoicePos__c> auxPositions = (List<InvoicePos__c>) JSON.deserialize(positions, List<InvoicePos__c>.class);

    	InvoiceService.save((Invoice__c) JSON.deserialize(draft, Invoice__c.class), auxPackages, auxPositions);
	}

	/**
	 * 
	 */
	@AuraEnabled
	public static Id cancel(Id invoiceId) {
		return InvoiceService.cancel(invoiceId).Id;
	}

	/**
	 * @description:	Pre-validate the Invoice.
	 * 					This duplicates some of the Invoice's Validation Rules. This is required because the insert/update
	 * 					operations are performed from a future method.
	 * 
	 * 					Note: This method is also called from the class ILVTabHelper.
	 * @When:	2023.11.23
	 * @Who:	david.sanchez@empaua.com
	 * 
	 * @param:	draft -- invoice draft to be created or updated
	 * 			userSettings -- user settings, some of which indicate whether validation can be overriden
	 * 			invoiceType -- indicates whether it is a 'Billing' or 'ILV' invoice.
	 * @return	If a validation fails, the error message; otherwise an empty string.
	 */
	public static String validateInvoice(Invoice__c draft, User userSettings, String invoiceType ) {
		
		if (String.isNotEmpty(draft.ProjectName__c)) {
			Project__c prj = [SELECT Id, ProjectCostCenter__c, TermsOfPayment__c, ValCountHasInvoiceDraft__c, VATPercent__c, BillingViaCompany__c, BillingViaCompany__r.AccountName__c
							  FROM Project__c WHERE Id = :draft.ProjectName__c];

			String VATPercent = draft.Id != null ? draft.VATPercent__c : prj.VATPercent__c;

			Invoice__c oldInvoice = new Invoice__c();
			if (draft.Id != null) {
				oldInvoice = [SELECT Id, VATPercent__c FROM Invoice__c WHERE id = :draft.Id];
			}

			Date fromFinanceDate = Date.newInstance(2024, 1, 1);
			Set<String> invalidVat = new Set<String>{'7.7%','2.5%','3.7%','8%'};
			
			System.debug('---InvoiceController.validateInvoiceLWC--- oldInvoice: '+oldInvoice);
			System.debug('---InvoiceController.validateInvoiceLWC--- FinanceDate__c: '+draft.FinanceDate__c);

			if (userSettings.PS480FunctionValidationRulesActive__c && !userSettings.IsFinanceManager__c) {
				
				CostCenter__c costCenter = [SELECT InvoiceDateLimit__c, FinanceDateLimit__c FROM CostCenter__c WHERE Id = :prj.ProjectCostCenter__c];

				String BillingViaCompanyAcctName = draft.Id != null ? draft.BillingViaCompany__r?.AccountName__c : prj.BillingViaCompany__r?.AccountName__c;

				System.debug('---InvoiceController.validateInvoiceLWC--- prj: '+prj);
				System.debug('---InvoiceController.validateInvoiceLWC--- costCenter: '+costCenter);
				System.debug('---InvoiceController.validateInvoiceLWC--- BillingViaCompanyAcctName: '+BillingViaCompanyAcctName);
				System.debug('---InvoiceController.validateInvoiceLWC--- VATPercent: '+VATPercent + ' old VATPercent: '+oldInvoice.VATPercent__c);

				if (draft.InvoiceDate__c < costCenter.InvoiceDateLimit__c) {
					return 'This invoice date is not allowed. Please get in touch with Finance.	(InvoiceController INO16)';
				}
				else if (draft.FinanceDate__c  < costCenter.FinanceDateLimit__c) {
					return 'This finance date is not allowed. Please get in touch with Finance.	(InvoiceController IN017)';
				}
				else if (prj.Id == null && prj.ValCountHasInvoiceDraft__c == 1) {
					return 'There is already an Invoice in Status "Draft". Please complete this invoice first. (InvoiceController IN012)';
				}
				else if (String.isEmpty(prj.TermsOfPayment__c)) {
					return 'Project must have a Terms of Payment. (InvoiceController IN015)';
				}
				else if (invoiceType == 'Billing') {
					if (draft.InvoiceTitle__c == null ||
						!draft.InvoiceTitle__c.containsIgnoreCase('Rechnung')   && !draft.InvoiceTitle__c.containsIgnoreCase('Invoice') &&
						!draft.InvoiceTitle__c.containsIgnoreCase('Gutschrift') && !draft.InvoiceTitle__c.containsIgnoreCase('Credit Note')) {
							return 'The Invoice Title must contain either "Rechnung" or "Invoice". (InvoiceController IN019)';
					}
				}
				else if (BillingViaCompanyAcctName != 'gateB (Singpore)' && VATPercent == '9%') {	// IN029_VAT_Not_9_Percent
					return 'You are not allowed to choose VAT 9%. Please get in touch with Finance. (InvoiceController IN029)';
				}
			}

			if (VATPercent != oldInvoice.VATPercent__c && draft.FinanceDate__c > fromFinanceDate && invalidVat.contains(VATPercent)) { //IN028_VAT_NewVATRates
				return 'You cannot use 7,7%, 2,5%, 3,7% or 8% as VAT from 01.01.2024 on. Please use instead 8,1%, 2,6%, 3,8% or respectively 9%. (InvoiceController IN028)';
			} 
		}

		return '';
	}

	/**
	 * Pre-validate the InvoicePosition.
	 */
	public static String validateInvoicePosition(List<InvoicePos__c> positions, User userSettings) {

		if (userSettings.PS480FunctionValidationRulesActive__c && !userSettings.IsFinanceManager__c) {
			Set<Id> posPkgIDs = new Set<Id>();
			Set<String> types = new Set<String>();
			for (InvoicePos__c invPos : positions) {
				posPkgIDs.add(invPos.PackageName__c);
			}

			Map<Id, Package__c> posPkg = new Map<Id, Package__c>([SELECT Id, PackageSuperior__c, RecordType.DeveloperName, 
																		 ProjectName__r.ProjectCostCenter__r.Name, PackageType__c, 
																		 PackageType2__c
																 FROM    Package__c WHERE Id IN :posPkgIDs]);

			for (InvoicePos__c invPos : positions) {
				Package__c pkg = posPkg.get(invPos.PackageName__c);
				System.debug('---InvoiceController.validateInvoicePosition--- InvoicePositionAmount__c: '+invPos.InvoicePositionAmount__c);
				if (invPos.PackageType__c != 'Group' && invPos.InvoicePositionAmount__c > 0 && !invPos.ShowPosition__c && String.isEmpty(pkg.PackageSuperior__c)) {
					return 'The Invoice Position with an Amount must be shown on the invoice. Please correct the checkboxes.';
				}
				else if ((invPos.ShowPositionAmount__c && !invPos.ShowPosition__c) || (invPos.ShowInvoiceText__c && !invPos.ShowPositionAmount__c && !invPos.ShowPosition__c) ) {
					return 'Checkboxes are not in line for billing template.';
				}
				else if (invPos.InvoicePositionAmount__c == null) {
					return 'The invoice position amount can not be empty. Please add a value or 0.';
				}
				// else if ((invPos.InvoicePositionAmount__c - invPos.InvoicePositionAmount__c.round(System.RoundingMode.DOWN)) != 0.0) {
				// 	System.debug('---InvoiceController.validateInvoicePosition--- InvoicePositionAmount__c Dec: '+(invPos.InvoicePositionAmount__c - invPos.InvoicePositionAmount__c.round(System.RoundingMode.DOWN)) );
				// 	return 'The Invoice Position must be without cents.';
				// }
			}
		}

		return '';
	}

}