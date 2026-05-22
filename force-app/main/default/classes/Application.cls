public with sharing class Application {

    // Configure and create the UnitOfWorkFactory for this Application
    public static final fflib_Application.UnitOfWorkFactory UnitOfWork =
            new fflib_Application.UnitOfWorkFactory(
                    new List<SObjectType>{
                            Account.SObjectType,
                            User.SObjectType,
                            Contact.SObjectType,
                            CostCenter__c.SObjectType,
                            FinanceAccount__c.SObjectType,
                            Project__c.SObjectType,
                            Package__c.SObjectType,
                            Time__c.SObjectType,
                            Expense__c.SObjectType,
                            SupplierCosts__c.SObjectType,
                            Invoice__c.SObjectType,
                            InvoicePos__c.SObjectType,
                            ILVPos__c.SObjectType,
                            PermissionSetAssignment.SObjectType,
                            Segment__c.SObjectType,
                            SupplierInvoice__c.SObjectType,
                            QuoteLineItem.SObjectType
                    }
            );

    // Configure and create the ServiceFactory for this Application
    public static final fflib_Application.ServiceFactory Service =
            new fflib_Application.ServiceFactory(
                    new Map<Type, Type>{
                            IUserService.class => UserServiceImpl.class,
                            IPackageService.class => PackageServiceImpl.class,
                            IInvoiceService.class => InvoiceServiceImpl.class,
                            IILVPosService.class => ILVPosServiceImpl.class
                    }
            );

    // Configure and create the SelectorFactory for this Application
    public static final fflib_Application.SelectorFactory Selector =
            new fflib_Application.SelectorFactory(
                    new Map<SObjectType, Type>{
                            DatedConversionRate.SObjectType => DatedConversionRateSelector.class,
                            Field__mdt.SObjectType => FieldMDTSelector.class,
                            InheritedFieldValue__mdt.SObjectType => InheritedFieldValueMDTSelector.class,
                            Object__mdt.SObjectType => ObjectMDTSelector.class,
                            ParentObjectUpdate__mdt.SObjectType => ParentObjectUpdateMDTSelector.class,
                            PermissionSet.SObjectType => PermissionSetSelector.class,
                            PermissionSetAssignment.SObjectType => PermissionSetAssignmentSelector.class,
                            PermissionSetAssigment__mdt.SObjectType => PermissionSetAssignmentMDTSelector.class,
                            ProjectEmployeeRate__c.SObjectType => ProjectEmployeeRateSelector.class,
                            User.SObjectType => UserSelector.class,
                            Project__c.SObjectType => ProjectSelector.class,
                            Package__c.SObjectType => PackageSelector.class,
                            Time__c.SObjectType => TimeSelector.class,
                            Account.SObjectType => AccountSelector.class,
                            Invoice__c.SObjectType => InvoiceSelector.class,
                            InvoicePos__c.SObjectType => InvoicePositionSelector.class,
                            ILVPos__c.SObjectType => ILVPosSelector.class,
                            FinanceAccount__c.SObjectType => FinanceAccountSelector.class,
                            CostCenter__c.SObjectType => CostCenterSelector.class,
                            Contact.SObjectType => ContactSelector.class,
                            Expense__c.SObjectType => ExpenseSelector.class,
                            SupplierCosts__c.SObjectType => SupplierCostsSelector.class,
                            Opportunity.SObjectType => OpportunitySelector.class,
                            OpportunityLineItem.SObjectType => OpportunityProductSelector.class,
                            Purchasing__c.SObjectType => PurchasingSelector.class,
                            QuoteLineItem.SObjectType => QuoteLineItemsSelector.class
                    }
            );

    // Configure and create the DomainFactory for this Application
    public static final fflib_Application.DomainFactory Domain =
            new fflib_Application.DomainFactory(
                    Application.Selector,
                    new Map<SObjectType, Type>{
                            Account.SObjectType => AccountDomain.Constructor.class,
                            User.SObjectType => UserDomain.Constructor.class,
                            Contact.SObjectType => ContactDomain.Constructor.class,
                            CostCenter__c.SObjectType => CostCenter.Constructor.class,
                            Field__mdt.SObjectType => FieldMDT.Constructor.class,
                            FinanceAccount__c.SObjectType => FinanceAccount.Constructor.class,
                            Invoice__c.SObjectType => Invoice.Constructor.class,
                            ILVPos__c.SObjectType => ILVPos.Constructor.class,
                            InheritedFieldValue__mdt.SObjectType => InheritedFieldValueMDT.Constructor.class,
                            InvoicePos__c.SObjectType => InvoicePosition.Constructor.class,
                            Package__c.SObjectType => PackageDomain.Constructor.class,
                            ParentObjectUpdate__mdt.SObjectType => ParentObjectUpdateMDT.Constructor.class,
                            PermissionSetAssignment.SObjectType => PermissionSetAssignmentDomain.Constructor.class,
                            PermissionSetAssigment__mdt.SObjectType => PermissionSetAssignmentMDT.Constructor.class,
                            Project__c.SObjectType => Project.Constructor.class,
                            ProjectEmployeeRate__c.SObjectType => ProjectEmployeeRate.Constructor.class,
                            Segment__c.SObjectType => Segment.Constructor.class,
                            SupplierCosts__c.SObjectType => SupplierCosts.Constructor.class,
                            SupplierInvoice__c.SObjectType => SupplierInvoice.Constructor.class,
                            Time__c.SObjectType => TimeDomain.Constructor.class,
                            Expense__c.SObjectType => Expense.Constructor.class,
                            QuoteLineItem.SObjectType => QuoteLineItems.Constructor.class,
                            ContentDocument.SObjectType => ContentDocuments.Constructor.class,
                            ContentDocumentLink.SObjectType => ContentDocumentLinks.Constructor.class
                    }
            );

}