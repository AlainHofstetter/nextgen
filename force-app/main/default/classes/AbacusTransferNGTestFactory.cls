@IsTest
public class AbacusTransferNGTestFactory {

    public static AbacusTransferNG__c buildOutboundPending(String interfaceType) {
        return new AbacusTransferNG__c(
            InterfaceType__c = interfaceType,
            Direction__c = 'Outbound',
            Status__c = 'Pending'
        );
    }

    public static AbacusTransferNG__c buildOutboundPending(String interfaceType, String sourceObject, Id sourceRecordId) {
        AbacusTransferNG__c row = buildOutboundPending(interfaceType);
        row.SourceObject__c = sourceObject;
        row.SourceRecordId__c = sourceRecordId;
        return row;
    }

    public static AbacusTransferNG__c buildInboundSent(String interfaceType) {
        return new AbacusTransferNG__c(
            InterfaceType__c = interfaceType,
            Direction__c = 'Inbound',
            Status__c = 'Sent',
            SentAt__c = DateTime.now()
        );
    }

    public static AbacusTransferNG__c buildFailed(String interfaceType, String error) {
        AbacusTransferNG__c row = buildOutboundPending(interfaceType);
        row.Status__c = 'Failed';
        row.LastError__c = error;
        row.LastHttpStatus__c = 500;
        row.RetryCount__c = 3;
        return row;
    }

    public static AbacusTransferNG__c insertOutboundPending(String interfaceType) {
        AbacusTransferNG__c row = buildOutboundPending(interfaceType);
        insert row;
        return row;
    }
}
