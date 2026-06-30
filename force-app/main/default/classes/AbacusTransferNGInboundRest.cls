@RestResource(urlMapping='/abacus/v1/inbound/*')
global with sharing class AbacusTransferNGInboundRest {

    private static final String CURRENCY_IMPORT = 'Currency Import';
    private static final String SUPPLIER_INVOICE_IMPORT = 'Supplier Invoice Import';

    @HttpPost
    global static InboundResponse handlePost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        String idempotencyKey = req.headers != null ? req.headers.get('Idempotency-Key') : null;
        if (String.isBlank(idempotencyKey)) {
            res.statusCode = 400;
            return new InboundResponse(null, 'error', 'Missing Idempotency-Key header');
        }

        List<AbacusTransferNG__c> existing = [
            SELECT Id, Status__c FROM AbacusTransferNG__c
            WHERE IdempotencyKey__c = :idempotencyKey LIMIT 1
        ];
        if (!existing.isEmpty()) {
            res.statusCode = 200;
            return new InboundResponse(existing[0].Id, 'duplicate', null);
        }

        Map<String, Object> bodyMap;
        try {
            bodyMap = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
        } catch (Exception e) {
            res.statusCode = 400;
            return new InboundResponse(null, 'error', 'Malformed JSON: ' + e.getMessage());
        }

        String type = (String) bodyMap.get('type');
        Map<String, Object> payload = (Map<String, Object>) bodyMap.get('payload');
        if (String.isBlank(type) || payload == null) {
            res.statusCode = 400;
            return new InboundResponse(null, 'error', 'Missing "type" or "payload"');
        }
        if (type != CURRENCY_IMPORT && type != SUPPLIER_INVOICE_IMPORT) {
            res.statusCode = 400;
            return new InboundResponse(null, 'error', 'Unknown interface type: ' + type);
        }

        String payloadJson = JSON.serializePretty(bodyMap);
        if (payloadJson.length() > 131071) payloadJson = payloadJson.substring(0, 131071);

        AbacusTransferNG__c row = new AbacusTransferNG__c(
            InterfaceType__c = type,
            Direction__c = 'Inbound',
            Status__c = 'Sent',
            SentAt__c = DateTime.now(),
            LastAttemptAt__c = DateTime.now(),
            IdempotencyKey__c = idempotencyKey,
            PayloadSnapshot__c = payloadJson
        );

        Savepoint sp = Database.setSavepoint();
        try {
            if (type == CURRENCY_IMPORT) {
                applyCurrencyImport(payload, row);
            } else if (type == SUPPLIER_INVOICE_IMPORT) {
                applySupplierInvoiceImport(payload, row);
            }
            insert row;
        } catch (Exception e) {
            Database.rollback(sp);
            row.Status__c = 'Failed';
            String err = e.getMessage() + '\n' + e.getStackTraceString();
            row.LastError__c = err.length() > 32767 ? err.substring(0, 32767) : err;
            insert row;
            res.statusCode = 500;
            return new InboundResponse(row.Id, 'failed', e.getMessage());
        }

        res.statusCode = 200;
        return new InboundResponse(row.Id, 'sent', null);
    }

    private static void applyCurrencyImport(Map<String, Object> payload, AbacusTransferNG__c row) {
        // TODO: confirm target writes for currency rates with finance.
        // Legacy wrote to standard CurrencyRate; multi-currency semantics depend on org setup.
        // For now, the audit row alone captures the inbound event.
    }

    private static void applySupplierInvoiceImport(Map<String, Object> payload, AbacusTransferNG__c row) {
        String abacusDocNr = (String) payload.get('abacusDocumentNr');
        if (String.isBlank(abacusDocNr)) {
            throw new InboundException('SupplierInvoiceImport: missing abacusDocumentNr');
        }
        SupplierInvoice__c si = new SupplierInvoice__c(
            AbacusDocumentNr__c = abacusDocNr
        );
        // TODO: fill remaining field mappings once REST contract is locked with Mule/Abacus.
        // Likely set: SupplierInvoiceTotal__c, SupplierInvoiceTotalCHF__c, SupplierInvoiceDate__c,
        //             LocalCurrency__c, Status__c, OrderReference__c, FinanceDate__c.
        Database.UpsertResult ur = Database.upsert(si, SupplierInvoice__c.AbacusDocumentNr__c, true);
        row.SupplierInvoice__c = ur.getId();
        row.SourceObject__c = 'SupplierInvoice__c';
        row.SourceRecordId__c = ur.getId();
    }

    global class InboundException extends Exception {}

    global class InboundResponse {
        public Id abacusTransferNGId;
        public String status;
        public String error;
        public InboundResponse(Id id, String status, String error) {
            this.abacusTransferNGId = id;
            this.status = status;
            this.error = error;
        }
    }
}
