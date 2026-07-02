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
        Integer keyMax = Schema.SObjectType.AbacusTransferNG__c.fields.IdempotencyKey__c.getLength();
        if (idempotencyKey.length() > keyMax) {
            res.statusCode = 400;
            return new InboundResponse(null, 'error', 'Idempotency-Key exceeds ' + keyMax + ' characters');
        }

        List<AbacusTransferNG__c> existing = [
            SELECT Id, Status__c FROM AbacusTransferNG__c
            WHERE IdempotencyKey__c = :idempotencyKey LIMIT 1
        ];
        // A Failed row means the previous attempt rolled back its target writes —
        // a retry with the same key must run again against that row, not report success.
        Id retryRowId = null;
        if (!existing.isEmpty()) {
            if (existing[0].Status__c != 'Failed') {
                res.statusCode = 200;
                return new InboundResponse(existing[0].Id, 'duplicate', null);
            }
            retryRowId = existing[0].Id;
        }

        Map<String, Object> bodyMap;
        try {
            bodyMap = (Map<String, Object>) JSON.deserializeUntyped(
                req.requestBody != null ? req.requestBody.toString() : null);
        } catch (Exception e) {
            res.statusCode = 400;
            return new InboundResponse(null, 'error', 'Malformed JSON: ' + e.getMessage());
        }
        if (bodyMap == null) {
            res.statusCode = 400;
            return new InboundResponse(null, 'error', 'Missing request body');
        }

        String type = (String) bodyMap.get('type');
        Object payloadObj = bodyMap.get('payload');
        if (String.isBlank(type) || !(payloadObj instanceof Map<String, Object>)) {
            res.statusCode = 400;
            return new InboundResponse(null, 'error', 'Missing "type" or "payload"');
        }
        if (type != CURRENCY_IMPORT && type != SUPPLIER_INVOICE_IMPORT) {
            res.statusCode = 400;
            return new InboundResponse(null, 'error', 'Unknown interface type: ' + type);
        }
        // Apex string comparison is case-insensitive; write the canonical picklist value.
        type = type == CURRENCY_IMPORT ? CURRENCY_IMPORT : SUPPLIER_INVOICE_IMPORT;
        Map<String, Object> payload = (Map<String, Object>) payloadObj;

        String payloadJson = JSON.serializePretty(bodyMap)
            .left(Schema.SObjectType.AbacusTransferNG__c.fields.PayloadSnapshot__c.getLength());

        AbacusTransferNG__c row = new AbacusTransferNG__c(
            Id = retryRowId,
            InterfaceType__c = type,
            Direction__c = 'Inbound',
            Status__c = 'Sent',
            SentAt__c = DateTime.now(),
            LastAttemptAt__c = DateTime.now(),
            LastError__c = null,
            LastHttpStatus__c = null,
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
            upsert row;
        } catch (Exception e) {
            Database.rollback(sp);
            // The target upsert was rolled back — drop references to records that no longer exist.
            row.SupplierInvoice__c = null;
            row.SourceObject__c = null;
            row.SourceRecordId__c = null;
            row.Status__c = 'Failed';
            row.SentAt__c = null;
            row.LastError__c = (e.getMessage() + '\n' + e.getStackTraceString())
                .left(Schema.SObjectType.AbacusTransferNG__c.fields.LastError__c.getLength());
            try {
                upsert row;
            } catch (Exception auditEx) {
                // Most likely a concurrent request committed the same key first
                // (IdempotencyKey__c is unique) — report it as the duplicate it is.
                List<AbacusTransferNG__c> winner = [
                    SELECT Id FROM AbacusTransferNG__c
                    WHERE IdempotencyKey__c = :idempotencyKey LIMIT 1
                ];
                if (!winner.isEmpty()) {
                    res.statusCode = 200;
                    return new InboundResponse(winner[0].Id, 'duplicate', null);
                }
                res.statusCode = 500;
                return new InboundResponse(null, 'failed', e.getMessage());
            }
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
