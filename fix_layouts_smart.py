import os, re

LAYOUTS_DIR = os.path.join('force-app', 'main', 'default', 'layouts')

# Fields that actually exist in Package__c (from field-meta.xml files)
PACKAGE_VALID_FIELDS = {
    'AbacusInbox__c', 'AbacusTimeTypeName__c', 'AbacusTimeType__c',
    'aupoaunr__c', 'aupoegr__c', 'aupokst__c', 'aupoparref__c', 'aupopoart__c', 'aupoponr__c',
    'BillingRatePercent__c', 'BriefingDeBriefingNotes__c', 'BudgetAssignPackage__c',
    'BudgetAssignTotalExpense__c', 'BudgetAssignTotalHours__c', 'BudgetAssignTotalSupplierCosts__c',
    'BudgetAssignTotalTime__c', 'BudgetNotes__c', 'BudgetOpenTotalExpense__c',
    'BudgetOpenTotalHours__c', 'CompletionRateTimePercent__c', 'CostCenterSegment__c',
    'CostsTotalAmountCHF__c', 'CostsTotalExpenseCHF__c', 'CostsTotalSupplierCostsCHF__c',
    'CostsTotalTimeCHF__c', 'EmployeeSpecificRate__c', 'EmployeeVacationBalance__c',
    'EmployeeVacationCredit__c', 'EmployeeVacationTotalHours__c', 'ExcludeFromExpenseAllowance__c',
    'ExcludeFromProjectMgmtAllowance__c', 'ExpenseAllowancePackage__c', 'ExpenseBillingType__c',
    'ExpenseDescription__c', 'FullCostsTotalTimeCHF__c', 'ILVPOSTotalAmountCHF__c',
    'ILVPOSTotalAmount__c', 'InvoicePOSTotalExpenseCHF__c', 'InvoicePOSTotalExpense__c',
    'InvoicePOSTotalSupplierCostsCHF__c', 'InvoicePOSTotalSupplierCosts__c',
    'InvoicePOSTotalTimeCHF__c', 'InvoicePOSTotalTime__c', 'InvoiceTotalAmountCHF__c',
    'LastTimeEntryDate__c', 'MarginAmountCHF__c', 'MarginPercent__c',
    'PackageBillingPositionText__c', 'PackageDescription__c', 'PackageNr__c',
    'PackageRateHour__c', 'PackageResponsibleBusiness__c', 'PackageSortNr__c',
    'PackageSpecificRate__c', 'PackageStatus__c', 'PackageSubType__c', 'PackageSuperior__c',
    'PackageType2__c', 'PackageType__c', 'ProjectCostCenter__c', 'ProjectCurrency__c',
    'ProjectManagementAllowancePackage__c', 'ProjectNameSearch__c', 'ProjectName__c',
    'ProjectNr__c', 'Project_Template__c', 'PurchasingCosts__c', 'PurchasingNotes__c',
    'Segment__c', 'ServicesTotalExpenseCHF__c', 'ServicesTotalExpense__c',
    'ServicesTotalHours__c', 'ServiceTotalExpenseCHFBP__c', 'ServiceTotalSupplierCostCHFBP__c',
    'ServiceTotalTimeCHFBP__c', 'ShowInvoiceText__c', 'ShowPositionAmount__c',
    'ShowPosition__c', 'Source__c', 'StaffNr__c', 'SupplierCostsGroup__c',
    'ValCheckValidPackage__c', 'ValCountHasExpenseCheckbox__c', 'ValCountHasExpense__c',
    'ValCountHasIlvPosCheckbox__c', 'ValCountHasILVPos__c', 'ValCountHasInvoicePosCheckbox__c',
    'ValCountHasInvoicePos__c', 'ValCountHasSupplierCostsCheckbox__c', 'ValCountHasSupplierCosts__c',
    'ValCountHasTimeCheckbox__c', 'ValCountHasTime__c', 'ValHasExpense__c', 'ValHasILVPos__c',
    'ValHasInvoicePos__c', 'ValHasPackage__c', 'ValHasSupplierCosts__c', 'ValHasTime__c',
    'ValNoDeletePRSPrintPlus__c', 'ZAbacusInterface__c', 'ZImportId__c', 'ZImportSource__c',
    'ZImportTimeStamp__c',
    # Standard fields always valid
    'Name', 'OwnerId', 'CreatedById', 'LastModifiedById', 'CreatedDate', 'LastModifiedDate',
    'RecordTypeId', 'CurrencyIsoCode', 'LastActivityDate', 'SystemModstamp',
}

# Fields that actually exist in Project__c
PROJECT_VALID_FIELDS = {
    'AbacusProjectAbbreviation__c', 'AbacusProjectName__c', 'AbacusProjectNr__c',
    'AbacusProjectResponsibleBusiness__c', 'AbacusProjectStatus__c', 'AbacusProjectType__c',
    'AbacusResponsible__c', 'AbacusSupplierCostImportDefault__c', 'ANrPrintPlus__c',
    'AprForecast__c', 'auauaunr__c', 'auauedat__c', 'auaustat__c', 'AugForecast__c',
    'BillingDelivery__c', 'BillingModelSpecialDeal__c', 'BillingModel__c', 'BillingNotes__c',
    'BillingViaCompany__c', 'BriefingDeBriefingNotes__c', 'BudgetAssignmentLight__c',
    'BudgetAssignTotalAmountCHF__c', 'BudgetAssignTotalAmount__c', 'BudgetAssignTotalExpenseCHF__c',
    'BudgetAssignTotalExpense__c', 'BudgetAssignTotalSupCostsCHF__c', 'BudgetAssignTotalSupplierCosts__c',
    'BudgetAssignTotalTimeCHF__c', 'BudgetAssignTotalTime__c', 'BudgetNotes__c',
    'BudgetOpenTotalExpense__c', 'BudgetQuoteTotalAmountCHF__c', 'BudgetQuoteTotalAmount__c',
    'BudgetQuoteTotalExpenseCHF__c', 'BudgetQuoteTotalExpense__c', 'BudgetQuoteTotalSupplierCostsCHF__c',
    'BudgetQuoteTotalSupplierCosts__c', 'BudgetQuoteTotalTimeCHF__c', 'BudgetQuoteTotalTime__c',
    'CancellationTotalAmountNetCHFBP__c', 'CompletionRatePercent__c', 'ContractPartnerSearch__c',
    'ContractPartner__c', 'CostCenterSegment__c', 'CostsTotalAmountCHF__c', 'CostsTotalExpenseCHF__c',
    'CostsTotalSupplierCostsCHF__c', 'CostsTotalTimeCHF__c', 'CurrencyRateToCHF__c',
    'CustomerOrderNr__c', 'CustomerReference__c', 'CYSendEmailProjectStatusClosed__c',
    'DecForecast__c', 'DefaultInvoiceDescription__c', 'DefaultInvoiceTitle__c',
    'ExpenseAllowancePercent__c', 'ExpenseBillingType__c', 'ExpenseDescription__c',
    'FebForecast__c', 'ILVForecastProject__c', 'ILVForecast__c', 'ILVTotalTimeCHF__c',
    'ILVTotalTime__c', 'InheritProjectResponsibleToPackages__c', 'InvoiceContact__c',
    'InvoiceOpenToBudget__c', 'InvoiceReceiver__c', 'InvoiceTotalAmountCHF__c',
    'InvoiceTotalAmountNetCHFBP__c', 'InvoiceTotalAmount__c', 'InvoiceTotalExpenseCHF__c',
    'InvoiceTotalExpense__c', 'InvoiceTotalServicesNetCHFBP__c', 'InvoiceTotalSupplierCostsCHF__c',
    'InvoiceTotalSupplierCosts__c', 'InvoiceTotalTimeCHF__c', 'InvoiceTotalTime__c',
    'IsActiveProjectResponsible__c', 'JanForecast__c', 'JulForecast__c', 'JunForecast__c',
    'LastTimeEntryDate__c', 'Licensor__c', 'MarForecast__c', 'MarginAmountCHF__c',
    'MarginPercent__c', 'MayForecast__c', 'NovForecast__c', 'OctForecast__c',
    'OpportunityName__c', 'OpportunityQuoteDescription__c', 'OpportunityQuoteNr__c',
    'PNrPrintPlus__c', 'ProductionApprovalDate__c', 'ProductionDeadlineDate__c',
    'ProjectCostCenter__c', 'ProjectCurrency__c', 'ProjectDescription__c', 'ProjectEndDate__c',
    'ProjectInvoiceDescription__c', 'ProjectManagementAllowancePercent__c',
    'ProjectManagementBillingType__c', 'ProjectManagementDescription__c', 'ProjectNameInternal__c',
    'ProjectNr__c', 'ProjectPartner__c', 'ProjectRateHour__c', 'ProjectReference__c',
    'ProjectResponsibilityCompany__c', 'ProjectResponsibleBusiness__c', 'ProjectResponsibleCustomer__c',
    'ProjectResponsibleTechnical__c', 'ProjectStartDate__c', 'ProjectStatus__c',
    'ProjectSubType__c', 'ProjectTemplate__c', 'ProjectType__c', 'Quote__c', 'RecordTypeID__c',
    'ReportExpenseMatrix__c', 'ReportSupplierCostsMatrix__c', 'ReportTimeByUnit__c',
    'ReportTimeDetail__c', 'ReportTimeMatrix__c', 'RestrictAccessToOwner__c',
    'RestrictAccessToUnit__c', 'RetrieveQuoteProducts__c', 'RollForecast__c', 'SepForecast__c',
    'ServicesTotalExpense__c', 'ServicesTotalHours__c', 'ServiceTotalExpenseCHFBP__c',
    'ServiceTotalSupplierCostBP__c', 'Source__c', 'StaffNr__c', 'SupplierCostsForecast__c',
    'TermsOfPayment__c', 'TotalForecast__c', 'ValCountAbacusInbox__c',
    'ValCountHasInvoiceCheckbox__c', 'ValCountHasInvoice__c', 'ValCountHasPackageCheckbox__c',
    'ValCountHasPackage__c', 'ValHasExpense__c', 'ValHasInvoice__c', 'ValHasPackage__c',
    'ValHasSupplierCosts__c', 'ValHasTime__c', 'ValProjectHide__c',
    'ValProjectPartnerNotProjectResponsibilit__c', 'VATPercent__c', 'x12Forecast__c',
    'ZImportId__c', 'ZImportSource__c', 'ZImportTimeStamp__c',
    # Standard fields
    'Name', 'OwnerId', 'CreatedById', 'LastModifiedById', 'CreatedDate', 'LastModifiedDate',
    'RecordTypeId', 'CurrencyIsoCode', 'LastActivityDate', 'SystemModstamp',
}

OBJECT_FIELD_MAP = {
    'Package__c': PACKAGE_VALID_FIELDS,
    'Project__c': PROJECT_VALID_FIELDS,
}

# Pattern to match a full layoutItems block with a field
layout_items_pattern = re.compile(
    r'\s*<layoutItems>\s*(?:<behavior>[^<]+</behavior>\s*)?<field>([^<]+)</field>\s*</layoutItems>',
    re.MULTILINE
)

total_removed = 0

for filename in os.listdir(LAYOUTS_DIR):
    if not filename.endswith('.layout-meta.xml'):
        continue

    # Determine which object this layout belongs to
    valid_fields = None
    for obj, fields in OBJECT_FIELD_MAP.items():
        if filename.startswith(obj):
            valid_fields = fields
            break
    if valid_fields is None:
        continue

    filepath = os.path.join(LAYOUTS_DIR, filename)
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find all fields used in this layout
    used_fields = layout_items_pattern.findall(content)
    invalid_fields = [f for f in used_fields if f not in valid_fields]

    if invalid_fields:
        print(f'\n{filename}:')
        for field in invalid_fields:
            print(f'  Removing: {field}')
            pattern = re.compile(
                rf'\s*<layoutItems>\s*(?:<behavior>[^<]+</behavior>\s*)?<field>{re.escape(field)}</field>\s*</layoutItems>',
                re.MULTILINE
            )
            content = pattern.sub('', content)
            total_removed += 1

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)

print(f'\nDone! Removed {total_removed} invalid field reference(s).')
