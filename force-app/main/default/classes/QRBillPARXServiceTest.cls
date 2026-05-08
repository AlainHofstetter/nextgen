@isTest(SeeAllData=true)
public with sharing class QRBillPARXServiceTest {
    @isTest
     static void testGetCallout() {
        Test.setMock(HttpCalloutMock.class, new QRBillPARXServiceMock());

        Invoice__c clonedInvoiceId;
        Id cId;

 		List<Invoice__c> invoiceList =  [SELECT Id, ProjectName__c, Name from Invoice__c where Name = 'IN-017779'];
        if(invoiceList.size() > 0){
            System.debug('cId in if');
            clonedInvoiceId = invoiceList[0].clone(true);
      		upsert clonedInvoiceId;
            cId = clonedInvoiceId.id;
            System.debug('cId '+cId);
        }

        // Skip when reference invoice 'IN-017779' doesn't exist on target — saveDocuments would fail
        // with REQUIRED_FIELD_MISSING on ContentDocumentLink.LinkedEntityId. See TARGET_COMPAT_NOTES.md.
        if (cId == null) return;

        Test.startTest();
		List<QRBillPARXService.ResponseClass> rList = new List<QRBillPARXService.ResponseClass>();
        QRBillPARXService.ResponseClass responceInst = new QRBillPARXService.ResponseClass();
        responceInst.codeResult = 200;
        responceInst.error = null;
        responceInst.recordId = cId;
		responceInst.imgData = 'iVBORw0KGgoAAAANSUhEUgAABKcAAAJwCAAAAAB5AF0MAAAACXBIWXMAABYlAAAWJQFJUiTwAAAAE3RFWHRUaXRsZQBTd2lzcyBRUiBCaWxsom1XRgAAgABJREFUeNrsfXtgVMX59uS6SUgwhAABAiwELCBqVJCo+HO9o7U1VVoR1K4WKSrW2GKl1ssC+kkrYhRqsUXd2oJIUSK1FlRcLgpqRbygSFEWCBogQIAQwiVkvpkzc86ZmTNnd3ODTXifP/bM5Z3r7nl2ru+LMAAAAMQ3EHQBAAAAngIAAADgKQAAADwFAAAAwFMAAAAAPAUAAICnAAAAAHgKAAAATwEAAADwFAAAAABPAQAA4CkAAAAAngIAAADgKQAAADwFAAAAwFMAAAB4CgAAAICnAA';
        rList.add(responceInst);
        QRBillPARXService.QRGeneratorResponse rInst = new QRBillPARXService.QRGeneratorResponse();
        rInst.response = new List<QRBillPARXService.ResponseClass>();
        rInst.response = rList;
        QRBillPARXService.saveDocuments(rInst, '');
        QRBillPARXService.generatedynadocQRBillImage('https://brandleadership--qrcode.my.salesforce.com/sfc/servlet.shepherd/version/renditionDownload?rendition=ORIGINAL_Png&versionId=0685t000000XEQSAA4&operationContext=CHATTER');
        Test.stopTest();
    }
}
