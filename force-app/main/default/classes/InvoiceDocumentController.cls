/*
 * @Class : InvoiceDocumentController
 * @Author     : Lisis Rodriguez <lisis.rodriguez@empaua.com>
 * @Created    : August 2023
 * @Description: Controller class for InvoicePDF and InvoiceCancelationPDF
 */
public with sharing class InvoiceDocumentController {
    public static final String INVOICE_NAME = 'Invoice';
    public static final String INVOICE_CANCELLATION_NAME = 'Invoice_Cancellation';
    public String imageURL { get; set; }
    public String projectName { get; set; }
    public static final String CALYDO = 'Calydo';
    public static final String GATEB = 'GateB';
    public static final String HOTZ = 'HBC';
    public static final String HILDA = 'Hilda';
    public static final String FOCUSNEXT = 'Focusnext';
    public static final String STUDIO_HOTZ = 'Studio Victor Hotz';
    public Project__c companyName { get; set; }
    public String imageFirstPage { get; set; }
    public Invoice__c invoiceRecord { get; set; }
    public String localisedDate { get; set; }
    public String localisedPeriodFrom { get; set; }
    public String localisedPeriodUntil { get; set; }
    public String termsOfPaymentLabel { get; set; }
    public List<InvoicePos__c> nonGroupInvPos { get; set; }
    public Map<String, InvoicePos__c> mapGroupNameAmount { get; set; } // @key: invoice position name @value: invoice position
    public Map<String, List<InvoicePos__c>> mapInvPosGroup { get; set; } // @key: name of the group @values: list of invoice positions

    /**
     * @param stdController
     */
    public InvoiceDocumentController(ApexPages.StandardController stdController) {
        this.invoiceRecord = (Invoice__c)stdController.getRecord();
        this.invoiceRecord = [
            SELECT Id, InvoiceTitle__c, ProjectName__r.Name, AccountLanguage__c, AccountNameLegal__c, InvoiceStatus__c, BillingNameAddition__c, 
                   BillingAddressStreetNr__c, BillingAddressAddition__c, BillingAddressPOBox__c, BillingAddressZIP__c, BillingAdressCity__c,
                   BillingAddressState__c, BillingAddressCountry__c, CancellationInvoiceDocumentNr__c, InvoiceDocumentNr__c, InvoiceContact__r.Name, 
                   InvoiceContact__r.FirstName, InvoiceContact__r.LastName, InvoiceContact__r.Phone, InvoiceContact__r.Email, CustomerReference__c, 
                   CustomerOrderNr__c, ShowProjectInvoiceDescription__c, InvoiceDescription__c, PeriodFrom__c, PeriodUntil__c, CancellationReason__c, 
                   ProjectInvoiceCurrency__c, TermsOfPayment2__c, BankName__c, BankLocation__c, IBAN__c, BankClearing__c, SWIFT__c, InvoiceTotalAmountNet__c,
                   InvoiceTotalAmountNetSGP__c, InvoiceTotalAmountNetGBP__c, InvoiceTotalAmountGross__c, InvoiceTotalAmountGrossSGP__c, InvoiceTotalAmountGrossGBP__c,
                   InvoiceVATAmount__c, InvoiceVATAmountSGP__c, InvoiceVATAmountGBP__c, 
                   InvoiceReceiver__r.BillingAddressLine2__c, InvoiceReceiver__r.BillingAddressLine3__c, InvoiceReceiver__r.BillingPoBox__c, 
                   InvoiceReceiver__r.BillingZip__c, InvoiceReceiver__r.BillingCity__c, InvoiceContact__c, AbacusBelegreferenz__c, InvoiceDate__c, 
                   VATPercent__c, OpportunityQuoteNr__c, InvoiceReceiver__r.BillingCountry__c, InvoiceReceiver__r.LocationCountry__c,
                   (SELECT Id, InvoicePositionName__c, InvoicePositionAmount__c, InvoicePositionSuperior__c,InvoicePositionSuperior__r.InvoicePositionName__c, 
                           PackageType__c, InvoicePositionText__c, ShowInvoiceText__c, PackageName__r.Name
                    FROM InvoicePos__r
                    WHERE ShowPosition__c = TRUE ORDER BY InvoicePositionSortNr__c ASC)
            FROM Invoice__c
            WHERE Id = :invoiceRecord.Id
        ];

        System.debug('---InvoiceDocumentController--- invoiceRecord: '+invoiceRecord);

        this.localisedDate = getFormattedInvoiceDate(invoiceRecord.InvoiceDate__c, invoiceRecord.AccountLanguage__c);
        this.localisedPeriodFrom = getFormattedInvoiceDate(invoiceRecord.PeriodFrom__c, invoiceRecord.AccountLanguage__c);
        this.localisedPeriodUntil = getFormattedInvoiceDate(invoiceRecord.PeriodUntil__c, invoiceRecord.AccountLanguage__c);
        this.imageFirstPage = '';
        this.termsOfPaymentLabel = getTermsOfPaymentLabel(invoiceRecord.TermsOfPayment2__c, invoiceRecord.AccountLanguage__c);
        this.projectName = invoiceRecord.ProjectName__r.Name.toUpperCase();

        System.debug('---InvoiceDocumentController--- projectName: '+projectName);

        this.mapInvPosGroup = new Map<String, List<InvoicePos__c>>();
        this.nonGroupInvPos = new List<InvoicePos__c>();
        this.mapGroupNameAmount = new Map<String, InvoicePos__c>();
        this.processInvoicePos(this.invoiceRecord.InvoicePos__r);

        System.debug('---InvoiceDocumentController--- mapInvPosGroup: '+mapInvPosGroup);

        System.debug('---InvoiceDocumentController--- --END--');
    }

    /*
     * @Method          :   processInvoicePos
     * @Author          :   Lisis Rodriguez <lisis.rodriguez@empaua.com>
     * @Created         :   12 Sept 2023
     * @Description     :   Populate mapInvPosGroup and nonGroupInvPos.
     *                      In an invoice there are 3 types of invoice positions: the fathers, the children (InvoicePositionSuperior__c is the id of the father),
     *                      and those that don't have children. We'll group the father and its children in mapInvPosGroup,
     *                      and the others in nonGroupInvPos.
     */
    @testVisible
    public void processInvoicePos(List<InvoicePos__c> initialInvPos) {
        Map<Id, String> mapNameGroup = new Map<Id, String>();

        System.debug('---InvoiceDocumentController.processInvoicePos--- initialInvPos['+initialInvPos.size()+']: '+initialInvPos);
        for (InvoicePos__c iInvPos : initialInvPos) {
            System.debug('---InvoiceDocumentController.processInvoicePos--- iInvPos: '+iInvPos);
            mapNameGroup.put(iInvPos.Id, iInvPos.InvoicePositionName__c);
            this.mapGroupNameAmount.put(iInvPos.InvoicePositionName__c, iInvPos);
        }

        System.debug('---InvoiceDocumentController.processInvoicePos--- mapGroupNameAmount['+this.mapGroupNameAmount.size()+']: '+this.mapGroupNameAmount);

        for (InvoicePos__c iInvPos : initialInvPos) {
            if (iInvPos.InvoicePositionSuperior__c != null) {
                // Populating mapInvPosGroup
                String groupName = mapNameGroup.get(iInvPos.InvoicePositionSuperior__c);
                System.debug('---InvoiceDocumentController.processInvoicePos--- groupName: '+groupName);

                if (groupName != null) {
                    // If the InvoicePositionSuperior__c is not null, then it's a child)
                    List<InvoicePos__c> listChildren;
                    if (!this.mapInvPosGroup.containsKey(groupName)) {
                        listChildren = new List<InvoicePos__c>();
                    } else {
                        listChildren = this.mapInvPosGroup.get(groupName);
                    }

                    if (!iInvPos.ShowInvoiceText__c) {
                        iInvPos.InvoicePositionText__c = null;
                    }

                    listChildren.add(iInvPos);
                    this.mapInvPosGroup.put(groupName, listChildren);
                }
            }
        }

        // Populating nonGroupInvPos
        for (InvoicePos__c iInvPos : initialInvPos) {
            if (iInvPos.InvoicePositionSuperior__c == null 
                && !this.mapInvPosGroup.containsKey(iInvPos.InvoicePositionName__c) 
                && iInvPos.PackageType__c != null
                && !iInvPos.PackageType__c.equalsIgnoreCase('group')) {
                // It doesn't belong to any group

                if (!iInvPos.ShowInvoiceText__c) {
                    iInvPos.InvoicePositionText__c = null;
                }

                this.nonGroupInvPos.add(iInvPos);
            }
        }

        System.debug('---InvoiceDocumentController.processInvoicePos--- mapInvPosGroup: '+this.mapInvPosGroup);
        System.debug('---InvoiceDocumentController.processInvoicePos--- nonGroupInvPos: '+this.nonGroupInvPos);
        System.debug('---InvoiceDocumentController.processInvoicePos--- --END-- ');
    }

    public static String formatAmountForSwiss(Decimal amount) {
        if (amount == null) {
            return '0.00';
        }
        String amountStr = amount.setscale(2).format();
        amountStr = amountStr.replace(',', '\''); // Replace comma with apostrophe
        return amountStr;
    }

    public void getImageURL() {
        System.debug('---InvoiceDocumentController.getImageURL--- --START-- ');
        // Check if the QR code already exists
        List<ContentDocumentLink> lstContentDocumentLinks = [
            SELECT Id, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :this.invoiceRecord.Id
            AND ContentDocument.Title LIKE :Label.QRInvoicePrefix + '%'
        ];

        System.debug('---InvoiceDocumentController.getImageURL--- lstContentDocumentLinks: '+lstContentDocumentLinks);
        System.debug('---InvoiceDocumentController.getImageURL--- BillingCountry__c: '+this.invoiceRecord.InvoiceReceiver__r.BillingCountry__c);

        // If the invoice doesn't have a QR code already, we generate it using the QRCodeService
        // QR Code are only needed for Swiss invoices.
        String billingCountry = String.isNotBlank(this.invoiceRecord.InvoiceReceiver__r.BillingCountry__c) ? 
                                    this.invoiceRecord.InvoiceReceiver__r.BillingCountry__c : this.invoiceRecord.InvoiceReceiver__r.LocationCountry__c;

        if (billingCountry == 'SWITZERLAND') {
            if (lstContentDocumentLinks.isEmpty()) {
                if (!Test.isRunningTest()) {
                    QRCodeService.generateQRCode(this.invoiceRecord);
                }
            }
            System.debug('---InvoiceDocumentController.getImageURL--- --After QRCodeService.generateQRCode- ');
        } else {
            System.debug('---InvoiceDocumentController.getImageURL--- --Not SWITZERLAND- ');
            return;
        }

        // Get the new QR code image generated
        lstContentDocumentLinks = [
            SELECT Id, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :this.invoiceRecord.Id
            AND ContentDocument.Title LIKE :Label.QRInvoicePrefix + '%'
        ];

        // Getting ContentVersion file using ContentDocument Id
        List<ContentVersion> versions = [
            SELECT Id, Title
            FROM ContentVersion
            WHERE ContentDocumentId = :lstContentDocumentLinks.get(0).ContentDocumentId
            ORDER BY CreatedDate DESC
        ];

        ContentVersion lastFile;
        if (!versions.isEmpty()) {
            lastFile = versions[0]; // The first record will be the latest due to ordering
        }

        // Create a new ContentDistribution record
        ContentDistribution newDistribution = new ContentDistribution(
            Name = lastFile.Title,
            ContentVersionId = lastFile.Id,
            PreferencesAllowViewInBrowser = true,
            PreferencesNotifyOnVisit = false       // Prevents the owner-first-view email
        );

        insert newDistribution; // Insert the new ContentDistribution record

        // Retrieve the newly created ContentDistribution record
        newDistribution = [
            SELECT Id, ContentDownloadUrl
            FROM ContentDistribution
            WHERE Id = :newDistribution.Id
        ];

        // Assign the ContentDownloadUrl to imageURL
        this.imageURL = newDistribution.ContentDownloadUrl;
    }

    // Any future dev having to untangle this mess.... I am sorry...
    private static String getTermsOfPaymentLabel(String termsOfPayment, String language) {
        // Define a map for translations
        String lang = 'en';
        if (language.equalsIgnoreCase('de')) {
            lang = 'de';
        }

        Map<String, Map<String, String>> translationsMap = new Map<String, Map<String, String>>{
            '1' => new Map<String, String>{
                'de' => '30 Tage Netto',
                'en' => '30 Days Net'
            },
            '10' => new Map<String, String>{
                'de' => '15 Tage Netto',
                'en' => '15 Days Net'
            },
            '13' => new Map<String, String>{
                'de' => '20 Tage Netto',
                'en' => '20 Days Net'
            },
            '14' => new Map<String, String>{
                'de' => 'Sofort',
                'en' => 'Immediately'
            },
            '15' => new Map<String, String>{
                'de' => '45 Tage Netto',
                'en' => '45 Days Net'
            },
            '2' => new Map<String, String>{
                'de' => '10 Tage 2%, 30 Tage Netto',
                'en' => '10 Days 2%, 30 Days Net'
            },
            '3' => new Map<String, String>{
                'de' => '10 Tage Netto',
                'en' => '10 Days Net'
            },
            '4' => new Map<String, String>{
                'de' => '30 Tage 2%',
                'en' => '30 Days 2%'
            },
            '5' => new Map<String, String>{
                'de' => '60 Tage Netto',
                'en' => '60 Days Net'
            },
            '7' => new Map<String, String>{
                'de' => '10 Tage 3%, 30 Tage Netto',
                'en' => '10 Days 3%, 30 Days Net'
            },
            '8' => new Map<String, String>{
                'de' => '90 Tage Netto',
                'en' => '90 Days Net'
            },
            '9' => new Map<String, String>{
                'de' => '15 Tage 2%, 30 Tage Netto',
                'en' => '15 Days 2%, 30 Days Net'
            }
            // Add additional values and translations as needed
        };

        // Check if the termsOfPayment exists in the map
        if (translationsMap.containsKey(termsOfPayment)) {
            Map<String, String> langMap = translationsMap.get(termsOfPayment);

            // Return the label based on the specified language
            if (langMap.containsKey(lang)) {
                return langMap.get(lang);
            }
        }

        // Return the default label or an empty string if not found
        return '';
    }

    /**
     * @param lstRequests
     */
    public static void createInvoicePDF(List<InvoiceInvocableService.Requests> lstRequests) {
        List<ContentVersion> lstInvoicePDFs = new List<ContentVersion>();

        for (InvoiceInvocableService.Requests iRequest : lstRequests) {
            Pagereference invoicePageRef;
            String docName;
            String compName;
            Id invoiceId = iRequest.invoiceId;

            Invoice__c inv = [
                SELECT Id, ProjectCostCenter__c, ProjectCostCenter__r.Active__c, ProjectCostCenter__r.Name, AccountLanguage__c, 
                       InvoiceVATAmount__c, VATPercent__c, InvoiceDocumentNr__c, ProjectCostCenter__r.LegalAccount__r.Name,
                       InvoiceReceiver__r.CurrencyIsoCode
                FROM Invoice__c
                WHERE Id = :invoiceId
            ];

            Boolean vatApplys = inv.VATPercent__c != '0%' && inv.VATPercent__c != null;

            if (iRequest.service == InvoiceInvocableService.SERVICE_CREATE_INVOICE) {
                docName = INVOICE_NAME + ' ' + inv.InvoiceDocumentNr__c;
                invoicePageRef = DeterminePageReference(inv.ProjectCostCenter__r.Name, inv.ProjectCostCenter__r.LegalAccount__r.Name, 
                                                        inv.InvoiceReceiver__r.CurrencyIsoCode, InvoiceInvocableService.SERVICE_CREATE_INVOICE, vatApplys);
            } else if (iRequest.service == InvoiceInvocableService.SERVICE_CANCEL_INVOICE) {
                docName = INVOICE_CANCELLATION_NAME + ' ' + inv.InvoiceDocumentNr__c;
                invoicePageRef = DeterminePageReference(inv.ProjectCostCenter__r.Name, inv.ProjectCostCenter__r.LegalAccount__r.Name, 
                                                        inv.InvoiceReceiver__r.CurrencyIsoCode, InvoiceInvocableService.SERVICE_CANCEL_INVOICE, vatApplys);
            }

            invoicePageRef.getParameters().put('id', iRequest.invoiceId);
            Blob documentBody;

            if (Test.IsRunningTest()) {
                documentBody = Blob.valueOf('Unit tests');
            } else {
                System.debug('---InvoiceDocumentController.createInvoicePDF--- Before getContentAsPDF');
                documentBody = invoicePageRef.getContentAsPDF();
                System.debug('---InvoiceDocumentController.createInvoicePDF--- After getContentAsPDF');
            }

            System.debug('---InvoiceDocumentController.createInvoicePDF--- documentBody: '+documentBody);

            ContentVersion documentPdf = new ContentVersion();
            documentPdf.ContentLocation = 'S';
            documentPdf.Origin = 'C';
            documentPdf.VersionData = documentBody;
            documentPdf.Title = docName + ' - ' + Date.today().format();
            documentPdf.PathOnClient = documentPdf.Title + '.pdf';
            documentPdf.FirstPublishLocationId = iRequest.invoiceId;
            lstInvoicePDFs.add(documentPdf);
        }

        if (!lstInvoicePDFs.isEmpty()) {
            insert lstInvoicePDFs;
        }
    }

    private static Pagereference DeterminePageReference(String costCenter, String legalAcct, String receiverCcy, Integer invoiceType, Boolean VatApplys) {
        Pagereference retVal;
        String upperCostCenter = costCenter.toUpperCase();

        Map<String, Map<String, PageReference>> costCenterPageMap = new Map<String, Map<String, PageReference>>{
            'GATEB_SINGAPORE' => new Map<String, PageReference>{
                'CREATE' => Page.InvoicePDF_GateB_SG,
                'CANCEL' => Page.InvoiceCancelPDF_GatebSingapore
            },            
            'GATEB_GBP' => new Map<String, PageReference>{
                'CREATE' => Page.InvoicePDF_GateB_GBP,
                'CANCEL' => Page.InvoiceCancelation //InvoicePCancelDF_GateB_GBP
            },
            'GATEB_GERMANY' => new Map<String, PageReference>{
                'CREATE' => Page.InvoicePDF_GateB_DE,
                'CANCEL' => Page.InvoiceCancelPDF_GatebDE
            },
            'GATEB_CH_GERMANY' => new Map<String, PageReference>{
                'CREATE' => Page.InvoicePDF_GateB_DE,
                'CANCEL' => Page.InvoiceCancelPDF_GatebCH_forDE
            },
            'GATEB_DEFAULT' => new Map<String, PageReference>{
                'CREATE' => Page.InvoicePDF_GateB_CH,
                'CANCEL' => Page.InvoiceCancelation
            },
            'CALYDO' => new Map<String, PageReference>{
                'CREATE' => Page.InvoicePDF_CY,
                'CANCEL' => Page.InvoiceCancelPDF_Calydo
            },
            'HOTZ' => new Map<String, PageReference>{
                'CREATE' => Page.InvoicePDF_Hotz,
                'CANCEL' => Page.InvoiceCancelPDF_Hotz
            },
            'HILDA' => new Map<String, PageReference>{
                'CREATE' => Page.InvoicePDF_Hilda, 
                'CANCEL' => Page.InvoiceCancelPDF_Hilda
            },
            'FOCUSNEXT' => new Map<String, PageReference>{
                'CREATE' => Page.InvoicePDF_Focusnext,
                'CANCEL' => Page.InvoiceCancelPDF_Focusnext
            },
            'STUDIO' => new Map<String, PageReference>{
                'CREATE' => Page.InvoicePDF_Studio_Hotz,
                'CANCEL' => Page.InvoiceCancelPDF_Studio_Hotz
            },
            'DEFAULT' => new Map<String, PageReference>{
                'CREATE' => Page.InvoicePDF_BLC,
                'CANCEL' => Page.InvoiceCancelPDF_BLC
            }
        };

        String mapKey;
        if (upperCostCenter.contains(GATEB.toUpperCase())) {
            if (costCenter.equalsIgnoreCase('GateB Singapore')) {
                mapKey = 'GATEB_SINGAPORE';
            }
            else if (receiverCcy == 'GBP') {
                mapKey = 'GATEB_SINGAPORE';
            }
            else if (legalAcct == 'gateB AG') {
                mapKey = 'GATEB_DEFAULT';
            }
            else {
                if (VatApplys) {
                    // VAT applys
                    if (costCenter.equalsIgnoreCase('GateB Germany')) {
                        mapKey = 'GATEB_GERMANY';
                    } else {
                        mapKey = 'GATEB_DEFAULT';
                    }
                } else {
                    mapKey = 'GATEB_CH_GERMANY';
                }
            }
        } else if (upperCostCenter.contains(CALYDO.toUpperCase())) {
            mapKey = 'CALYDO';
        } else if (upperCostCenter.contains(HOTZ.toUpperCase())) {
            mapKey = 'HOTZ';
        } else if (upperCostCenter.contains(HILDA.toUpperCase())) {
            mapKey = 'HILDA';
        } else if (upperCostCenter.contains(FOCUSNEXT.toUpperCase())) {
            mapKey = 'FOCUSNEXT';
        } else if (upperCostCenter.contains(STUDIO_HOTZ.toUpperCase())) {
            mapKey = 'STUDIO';
        } else {
            mapKey = 'DEFAULT';
        }

        String actionType = invoiceType == InvoiceInvocableService.SERVICE_CREATE_INVOICE ? 'CREATE' : 'CANCEL';

        return costCenterPageMap.get(mapKey).get(actionType);
    }

    private static String getFormattedInvoiceDate(Date d, String language) {
        if (d == null) {
            return '';
        }
        if (language.equalsIgnoreCase('DE')) {
            return DateUtils.formatDateInGerman(d);
        } else {
            DateTime myDateTime = DateTime.newInstance(d.year(), d.month(), d.day());
            // Format the date
            return myDateTime.format('d. MMMM yyyy');
        }
    }
}