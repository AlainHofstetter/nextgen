/**
* @author TSC
* @date 18.06.2016
* @description Email inbound class to create BLCTicket for incoming mail and add attachments
*/

global class InboundEmailHandlerBLCTicket implements Messaging.InboundEmailHandler {
    
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        BLCTickets__c ticket = new BLCTickets__c();
        
        ticket.RecordTypeId = [SELECT Id, DeveloperName, SobjectType FROM RecordType where SobjectType = 'BLCTickets__c' and DeveloperName = 'It'].Id;
        ticket.Origin__c = 'Email';
        ticket.Status__c = 'New';
        
        ticket.Subject__c = email.Subject;
        ticket.Description__c = email.PlainTextBody;
        ticket.EmailSender__c = email.FromAddress;
        insert ticket;
        
        // Save attachments, if any
        if (email.textAttachments != null)
        {
            for(Messaging.Inboundemail.TextAttachment tAttachment : email.textAttachments)
            {
                Attachment attachment = new Attachment();
                
                attachment.Name = tAttachment.fileName;
                attachment.Body = Blob.valueOf(tAttachment.body);
                attachment.ParentId = ticket.Id;
                insert attachment;
            }
            
        }
        
        //Save any Binary Attachment
        
        if (email.binaryAttachments != null)
        {
            for(Messaging.Inboundemail.BinaryAttachment bAttachment : email.binaryAttachments) {
                Attachment attachment = new Attachment();
                
                attachment.Name = bAttachment.fileName;
                attachment.Body = bAttachment.body;
                attachment.ParentId = ticket.Id;
                insert attachment;
            }
        } 
        
        
        
        result.success = true;
        return result;
        
        
    }
}