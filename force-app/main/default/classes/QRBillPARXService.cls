/**
 * QRBillPARXService
 
 *@author ldo
 * @copyright PARX
 *
*/
public class QRBillPARXService {

    public static final String DOCUMENT_NAME = 'QRBillInvoice - ';
    public static final String CALL_RESULT_OK = 'OK';
    public static final String ERRORSTRING = 'Public link not generated';

    // Web Service information
    public final static String METHOD_WS = 'POST';

    public final static String DOMAIN = URL.getSalesforceBaseUrl().toExternalForm();
    public static String FORMULA_IMG = '/sfc/servlet.shepherd/version/renditionDownload?rendition=ORIGINAL_Png&versionId={ContentVersionID}&operationContext=CHATTER';

    public static String qrBillImagePublicLink ='';

    /**
     * qrBillGenerator: method to call Heroku for QR Bill generation
     *
     * ## objectJson (String): objectJson 
     * ## format (String): format
     */
    @future (callout=true)
    public static void qrBillGenerator(String objectJson, String docFormat, List<String> objectsIds){
        System.debug('***** In QRBillGenerator');
        try {
            System.debug('***** In try');
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:Heroku_QR_Bill_code');
            //request.setEndpoint('https://dynadoc-qr-bill-parx.herokuapp.com/qrcode');
            request.setMethod(METHOD_WS);
            request.setBody(objectJson);
            request.setHeader('Content-Type', 'application/json');

            System.debug('***** Calling request body'+request.getBody()); 
            HttpResponse response = http.send(request);
            System.debug('***** response '+response);

            if (response.getStatusCode() == 200) {
                System.debug('***** In If 200 response');
                String responseBody = response.getBody();
                QRGeneratorResponse responseObj = (QRGeneratorResponse) JSON.deserialize(responseBody, QRGeneratorResponse.class);                    
                saveDocuments(responseObj, docFormat);
                System.debug('***** AFTER SAVBEDOCS');
            } else {
                System.debug('***** In If 200 else response');
                system.debug('***** response.getStatusCode(): '+response.getStatusCode());
                system.debug('***** response.getBody(): '+response.getBody());
                generateError(objectsIds, response.getBody());
            }
        } catch (Exception ex) {
            generateError(objectsIds, ex.getMessage());
        }
    }

    /**
     * generateError: method for creating the event for error notification
     *
     * ## objectsIds (List<String>): objectsIds
     * ## error (String): error
     */
    public static void generateError(List<String> objectsIds, String error){
        Map<String, ResponseClass> mapError = new Map<String, ResponseClass>();
            for(String key : objectsIds){
                ResponseClass resp = new ResponseClass();
                resp.recordId = key; 
                resp.codeResult = 500; 
                resp.error = error;
                mapError.put(key, resp);
            }
            createObjectEvent(new Map<String, String>(),mapError);
    }

    /**
     * saveDocuments: method that proceeds to the creation of the ContentDocumentLink and the ContentVersion to attach to the record
     *
     * ## recordId (String): recordId
     * ## file (String): file
     * ## format (String): format
     */
    public static void saveDocuments(QRGeneratorResponse responseObj, String format){
        System.debug('***** In saveDocuments');
        List<String> recordsIds = new List<String>();
        List<ContentVersion> cvToInsert = new List<ContentVersion>();
        List<ContentDocumentLink> cdlListToInsert = new List<ContentDocumentLink>();
        Map<String, String> mappingValues = new Map<String, String>();
        Map<String, ResponseClass> mapErrors = new Map<String, ResponseClass>();
        String currDate = system.now().format();

        for(ResponseClass response : responseObj.response){
            System.debug('***** In saveDocuments response'+response);
            System.debug('***** In saveDocuments response.codeResult'+response.codeResult);
            
            if(response.codeResult == 200){
                ContentVersion cv = new ContentVersion(
                    Title= DOCUMENT_NAME+' '+currDate, 
                    PathOnClient = DOCUMENT_NAME+' '+currDate+'.'+format,
                    VersionData = EncodingUtil.base64Decode(response.imgData), 
                    origin = 'H'
                );

                recordsIds.add(response.recordId);
                cvToInsert.add(cv);
                System.debug('***** In if saveDocuments cv'+cv);
            } else mapErrors.put(response.recordId, response);
        }

        Database.SaveResult[] srList = Database.insert(cvToInsert, false);

        for (Database.SaveResult sr : srList) {

            String recordId = recordsIds.get(srList.indexOf(sr));
            if (sr.isSuccess()) {
                mappingValues.put(sr.getId(), recordId);
            }
        }

        if(QRBillPARXHandler.cnt == 0){
        for(ContentVersion cv : [SELECT ContentDocumentId FROM ContentVersion WHERE Id in :mappingValues.keySet() ]){
            ContentDocumentLink newCdl = new ContentDocumentLink();
            System.debug('***** In if saveDocuments LinkedEntityId '+mappingValues.get(cv.Id));
            newCdl.LinkedEntityId = mappingValues.get(cv.Id);
            newCdl.contentdocumentid = cv.ContentDocumentId;
            newCdl.ShareType = 'V';
            cdlListToInsert.add(newCdl);
            QRBillPARXHandler.cdrecursion = true;
        }
        insert cdlListToInsert;
        QRBillPARXHandler.cnt++;
        System.debug('***** Calling CreateEvent');
        createObjectEvent(mappingValues, mapErrors);
        System.debug('***** Completing CreateEvent');
        }
    }  

    /**
     * createObjectEvent: method that creates the platform event to allow the record to be updated
     *
     * ## mapValues (Map<StringString>): mapValues
     */
    public static void createObjectEvent(Map<String, String> mapValues, Map<String, ResponseClass> mapResults){
        System.debug('***** In createObjectEvent');
        List<QR_Bill_Update_Event__e> events = new List<QR_Bill_Update_Event__e>();
        
        for(String key : mapValues.keySet()){
            System.debug('***** In createObjectEvent for1');
            events.add(new QR_Bill_Update_Event__e(
                Record_Id__c = mapValues.get(key),
                Content_Version_Id__c = key,
                Code_result__c = 200
            ));
        }

        for(String key : mapResults.keySet()){
            System.debug('***** In createObjectEvent for2');
            events.add(new QR_Bill_Update_Event__e(
                Record_Id__c = key,
                Error__c = mapResults.get(key).error,
                Code_result__c = Integer.valueOf(mapResults.get(key).codeResult)
            ));
        }
        System.debug('***** In createObjectEvent publishing');
        EventBus.publish(events);  
    }

    /**
     * updateQRBill: method to update the QRBillImage__c field with the new document reference value
     *
     * ## newEvents (List<QR_Bill_Update_Event__e>): newEvents
     */
    public static void updateQRBill(List<QR_Bill_Update_Event__e> newEvents){
        
        System.debug('***** In updateQRBill');
        
        List<SObject> objectListToUpdate = new List<SObject>();
        try {
            for(QR_Bill_Update_Event__e evt : newEvents){
                
                Id idToUpdate = evt.Record_Id__c;
                SObject objToUpdate = idToUpdate.getSObjectType().newSObject(idToUpdate);

                if(evt.Code_result__c == 200){
                    String valueToSet = FORMULA_IMG.replace('{ContentVersionID}', evt.Content_Version_Id__c);
                    objToUpdate.put('QRBillImage__c', DOMAIN+valueToSet);
                    objToUpdate.put('QRBillResult__c', CALL_RESULT_OK);
                    objToUpdate.put('QRBillResultStatusCode__c', 200);
                    String dynadocQRBillImage = generatedynadocQRBillImage(DOMAIN+valueToSet);
                    objToUpdate.put('DynadocQRBillImage__c',dynadocQRBillImage);  
                } else {
                    objToUpdate.put('QRBillImage__c', null);
                    objToUpdate.put('QRBillResult__c', String.isNotBlank(evt.Error__c) ? evt.Error__c: Label.QR_Bill_Code_Generic_Error);
                    objToUpdate.put('QRBillResultStatusCode__c', evt.Code_result__c);
                }
                system.debug('evt.Error__c: '+evt.Error__c);
                objectListToUpdate.add(objToUpdate);
            }
            QRBillPARXHandler.recursion = true;
            Database.SaveResult [] updateResult = Database.update(objectListToUpdate, false);
            for (Database.SaveResult r : updateResult)
            {
                if (!r.isSuccess())
                {
                    for (Database.Error e : r.getErrors())
                        
                    { system.debug(e.getMessage() ); }
                }
            }
            //update objectListToUpdate;
        } catch (Exception ex) {
            system.debug(ex.getMessage());
        }
    }

  public static String generatedynadocQRBillImage(String valToSet){
        String dynadocQRBillImg = '';

        String SERVSHEP = 'servlet.shepherd';
        String OPCONTXT = '&operationContext';
        String VERID = '&versionId=';
        String versionId = '';
        ContentVersion contentId;
        String publicLink;
        List<ContentDistribution> contentDbLst;
        
        dynadocQRBillImg += 'https://brandleadership.my.salesforce.com/sfc/';
        System.debug('***** dynadocQRBillImg1 '+dynadocQRBillImg);

        dynadocQRBillImg += 'dist';
        System.debug('***** dynadocQRBillImg2 '+dynadocQRBillImg);

        dynadocQRBillImg += ''+(((valToSet.split(SERVSHEP)[1]).split(OPCONTXT))[0]);
        System.debug('***** dynadocQRBillImg3 '+dynadocQRBillImg);

        versionId = (((valToSet.split(SERVSHEP)[1]).split(OPCONTXT))[0]).split(VERID)[1];
        //dynadocQRBillImg += ''+versionId;
        System.debug('***** versionId '+versionId);

        List<ContentVersion> contentBodyIdLst = [SELECT Id,ContentBodyId FROM ContentVersion WHERE Id =: versionId];
        if(contentBodyIdLst.size() > 0){
        contentId = contentBodyIdLst[0];
        dynadocQRBillImg += '&contentId='+contentBodyIdLst[0].ContentBodyId;
        System.debug('***** dynadocQRBillImg4 '+dynadocQRBillImg);

      	publicLink = createPublicLinkForFile1(contentBodyIdLst[0].Id);
        contentDbLst = [SELECT DistributionPublicUrl FROM ContentDistribution WHERE ContentVersionId =: contentBodyIdLst[0].Id];
      
      	if(contentDbLst.size() > 0 && contentDbLst[0].DistributionPublicUrl != null)
        //dynadocQRBillImg += '&page=0&d=/a/'+(contentDbLst[0].DistributionPublicUrl).split('/a')[1];
        dynadocQRBillImg += '&d=/a'+(contentDbLst[0].DistributionPublicUrl).split('/a')[1];
        System.debug('***** dynadocQRBillImg5 '+dynadocQRBillImg);  
		}
      
        dynadocQRBillImg += '&oid='+UserInfo.getOrganizationId();
        System.debug('***** dynadocQRBillImg6 '+dynadocQRBillImg);
        return dynadocQRBillImg;
    }  
    
    public static String createPublicLinkForFile1(Id contentVersionId){
        ContentDistribution cd = new ContentDistribution();
        cd.Name = 'Test';
        cd.ContentVersionId = contentVersionId;
        cd.PreferencesAllowViewInBrowser= true;
        cd.PreferencesLinkLatestVersion=true;
        cd.PreferencesNotifyOnVisit=false;
        cd.PreferencesPasswordRequired=false;
        cd.PreferencesAllowOriginalDownload= true;
        insert cd;
        return cd.DistributionPublicUrl;
    }
    
    public static void createPublicLinkForFile(List<ContentVersion> contentVersions){
        ContentDistribution[] distributionsToInsert = new List<ContentDistribution>();
        for(ContentVersion objContentVersion : contentVersions){
            //if image uploaded then only create public link
            if(objContentVersion.FileType.toLowerCase()=='jpg'){
                system.debug('objContentVersion.FileExtension.toLowerCase():' + objContentVersion.FileType);
                
                distributionsToInsert.add(createContentDistribution(objContentVersion.Id));
            }
        }
        if(!distributionsToInsert.isEmpty())
        {
            insert distributionsToInsert;
        }
    }
    
    public static ContentDistribution createContentDistribution(Id contentVersionId){
        ContentDistribution newDist = new ContentDistribution();
        newDist.ContentVersionId = contentVersionId;
        newDist.Name = 'External Link';
        newDist.PreferencesNotifyOnVisit = false;
        newDist.PreferencesAllowViewInBrowser = true;
        newDist.PreferencesAllowOriginalDownload=true;
        system.debug('createContentDistribution creted');
        return newDist;
    }    
        
    /**
     * ResponseClass: Wrapper response
     *
     */
    public class QRGeneratorResponse{
        public List<ResponseClass> response;
    }

    /**
     * ResponseClass: Wrapper response body
     *
     */
    public class ResponseClass{
        public String recordId;
        public String imgData;
        public Integer codeResult;
        public String error;
    }
}