public with sharing class InvoiceSelector extends fflib_SObjectSelector
        implements IInvoiceSelector {

    public static IInvoiceSelector newInstance() {
        return (IInvoiceSelector) Application.Selector.newInstance(Invoice__c.SObjectType);
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
                Invoice__c.AbacusInvoicePOSTotal__c,
                Invoice__c.AbacusTransfer__c,
                Invoice__c.AccountNameLegal__c,
                Invoice__c.BillingAddressAddition__c,
                Invoice__c.BillingAddressCountry__c,
                Invoice__c.BillingAddressPOBox__c,
                Invoice__c.BillingAddressState__c,
                Invoice__c.BillingAddressStreetNr__c,
                Invoice__c.BillingAddressZIP__c,
                Invoice__c.BillingAdressCity__c,
                Invoice__c.BillingNameAddition__c,
                Invoice__c.BillingViaCompany__c,
                Invoice__c.BillingViaLegalCode__c,
                Invoice__c.CancellationInvoiceRelation__c,
                Invoice__c.CancellationReason__c,
                Invoice__c.ConnectionReceivedId,
                Invoice__c.ConnectionSentId,
                Invoice__c.ContractPartner__c,
                Invoice__c.CreatedById,
                Invoice__c.CreatedDate,
                Invoice__c.CurrencyIsoCode,
                Invoice__c.CurrencyRateToCHF__c,
                Invoice__c.CustomerOrderNr__c,
                Invoice__c.CustomerReference__c,
                Invoice__c.FinanceDate__c,
                Invoice__c.ILVPOSTotalExpenseCHF__c,
                Invoice__c.ILVPOSTotalExpense__c,
                Invoice__c.ILVPOSTotalSupplierCostCHF__c,
                Invoice__c.ILVPOSTotalSupplierCost__c,
                Invoice__c.ILVPOSTotalTimeCHF__c,
                Invoice__c.ILVPOSTotalTime__c,
                Invoice__c.Id,
                Invoice__c.InvoiceDate__c,
                Invoice__c.InvoiceDescription__c,
                Invoice__c.InvoiceDocumentNr__c,
                Invoice__c.InvoiceInvalid__c,
                Invoice__c.InvoicePOSTotalExpenseCHF__c,
                Invoice__c.InvoicePOSTotalExpense__c,
                Invoice__c.InvoicePOSTotalSupplierCostCHF__c,
                Invoice__c.InvoicePOSTotalSupplierCost__c,
                Invoice__c.InvoicePOSTotalTimeCHF__c,
                Invoice__c.InvoicePOSTotalTime__c,
                Invoice__c.InvoiceReceiver__c,
                Invoice__c.InvoiceSentDate__c,
                Invoice__c.InvoiceStatus__c,
                Invoice__c.InvoiceTitle__c,
                Invoice__c.InvoiceTotalAmountGrossCHF__c,
                Invoice__c.InvoiceTotalAmountGross__c,
                Invoice__c.InvoiceTotalAmountNetCHF__c,
                Invoice__c.InvoiceTotalAmountNet__c,
                Invoice__c.InvoiceType__c,
                Invoice__c.InvoiceValutaDate__c,
                Invoice__c.IsDeleted,
                Invoice__c.LastActivityDate,
                Invoice__c.LastModifiedById,
                Invoice__c.LastModifiedDate,
                Invoice__c.LastReferencedDate,
                Invoice__c.LastViewedDate,
                Invoice__c.Name,
                Invoice__c.PeriodFrom__c,
                Invoice__c.PeriodUntil__c,
                Invoice__c.ProjectCostCenter__c,
                Invoice__c.ProjectInvoiceCurrency__c,
                Invoice__c.ProjectInvoiceDescription__c,
                Invoice__c.ProjectName__c,
                Invoice__c.ProjectNr__c,
                Invoice__c.RecordTypeId,
                Invoice__c.RelevantToRevenue__c,
                Invoice__c.ShowProjectInvoiceDescription__c,
                Invoice__c.SystemModstamp,
                Invoice__c.TermsOfPayment__c,
                Invoice__c.VATPercent__c,
                Invoice__c.ValCheckValidInvoice__c,
                Invoice__c.ValNoDeleteOverrideSysadmin__c,
                Invoice__c.ValNoDelete__c,
                Invoice__c.ZImportId__c,
                Invoice__c.ZImportSource__c,
                Invoice__c.ZImportTimeStamp__c
        };
    }

    public Schema.SObjectType getSObjectType() {
        return Invoice__c.sObjectType;
    }

    public List<Invoice__c> selectWithRelated(Set<Id> ids, Set<String> related) {
        fflib_QueryFactory query = newQueryFactory();
        query.selectFields(related);

        query.setCondition('id in :ids');
        return (List<Invoice__c>) Database.query(query.toSOQL());
    }

    public Invoice__c draftByProject(Id projectId, String invoiceType) {
        fflib_QueryFactory query = newQueryFactory(false);
        query.selectFields(new Set<String>{
                'InvoiceTitle__c',
                'InvoiceDescription__c',
                'ProjectInvoiceDescription__c',
                'InvoiceDate__c',
                'FinanceDate__c',
                'InvoiceStatus__c',
                'PeriodFrom__c',
                'PeriodUntil__c',
                'AccountNameLegal__c',
                'BillingNameAddition__c',
                'BillingAddressStreetNr__c',
                'BillingAddressAddition__c',
                'BillingAddressPOBox__c',
                'BillingAddressZIP__c',
                'BillingAdressCity__c',
                'BillingAddressState__c',
                'BillingAddressCountry__c',
                'BillingViaCompany__c',
                'BillingViaCompany__r.AccountName__c',
                'InvoiceDate__c',
                'FinanceDate__c',
                'PeriodFrom__c',
                'PeriodUntil__c',
                'ProjectInvoiceCurrency__c',
                'VATPercent__c',
                'TermsOfPayment2__c',
                'CustomerOrderNr__c',
                'CustomerReference__c',
                'InvoiceTotalAmountNet__c',
                'InvoiceVatAmount__c',
                'InvoiceTotalAmountGross__c',
                'InvoiceVatAmount__c'
        });
        query.setCondition('ProjectName__c = :projectId AND InvoiceStatus__c = \'Draft\' AND RecordType.Name = :invoiceType');

        String soql = query.toSOQL()
                .replaceFirst('TermsOfPayment2__c', 'toLabel(TermsOfPayment2__c)');

        System.debug('---InvoiceSelector.draftByProject--- soql: '+soql);
        List<Invoice__c> invoices = (List<Invoice__c>) Database.query(soql);

        System.debug('---InvoiceSelector.draftByProject--- invoices: '+invoices);

        return invoices == null || invoices.isEmpty() ? null : invoices[0];
    }

    public List<ContentDocumentLink> selectDocuments(Set<Id> ids) {
        return [
                SELECT ContentDocumentId, LinkedEntityId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN  :ids
        ];
    }

}