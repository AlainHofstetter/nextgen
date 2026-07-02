@IsTest
private class AbacusTransferNGInboundRestTest {

    @IsTest
    static void missingIdempotencyKeyReturns400() {
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('{}');
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        AbacusTransferNGInboundRest.InboundResponse out = AbacusTransferNGInboundRest.handlePost();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals('error', out.status);
    }

    @IsTest
    static void duplicateIdempotencyKeyReturnsExistingRow() {
        AbacusTransferNG__c existing = AbacusTransferNGTestFactory.buildInboundSent('Currency Import');
        existing.IdempotencyKey__c = 'dup-key-001';
        insert existing;

        RestRequest req = new RestRequest();
        req.headers.put('Idempotency-Key', 'dup-key-001');
        req.requestBody = Blob.valueOf('{"type":"Currency Import","payload":{}}');
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        AbacusTransferNGInboundRest.InboundResponse out = AbacusTransferNGInboundRest.handlePost();

        System.assertEquals('duplicate', out.status);
        System.assertEquals(existing.Id, out.abacusTransferNGId);
        System.assertEquals(1, [SELECT COUNT() FROM AbacusTransferNG__c WHERE IdempotencyKey__c = 'dup-key-001']);
    }

    @IsTest
    static void malformedJsonReturns400() {
        RestRequest req = new RestRequest();
        req.headers.put('Idempotency-Key', 'bad-json-001');
        req.requestBody = Blob.valueOf('not json');
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        AbacusTransferNGInboundRest.InboundResponse out = AbacusTransferNGInboundRest.handlePost();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals('error', out.status);
    }

    @IsTest
    static void unknownTypeReturns400() {
        RestRequest req = new RestRequest();
        req.headers.put('Idempotency-Key', 'unknown-type-001');
        req.requestBody = Blob.valueOf('{"type":"SomethingElse","payload":{"x":1}}');
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        AbacusTransferNGInboundRest.InboundResponse out = AbacusTransferNGInboundRest.handlePost();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals('error', out.status);
        System.assertEquals(0, [SELECT COUNT() FROM AbacusTransferNG__c WHERE IdempotencyKey__c = 'unknown-type-001']);
    }

    @IsTest
    static void oversizedIdempotencyKeyReturns400() {
        RestRequest req = new RestRequest();
        req.headers.put('Idempotency-Key', 'x'.repeat(41));
        req.requestBody = Blob.valueOf('{"type":"Currency Import","payload":{}}');
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        AbacusTransferNGInboundRest.InboundResponse out = AbacusTransferNGInboundRest.handlePost();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals('error', out.status);
        System.assertEquals(0, [SELECT COUNT() FROM AbacusTransferNG__c]);
    }

    @IsTest
    static void nullJsonBodyReturns400() {
        RestRequest req = new RestRequest();
        req.headers.put('Idempotency-Key', 'null-body-001');
        req.requestBody = Blob.valueOf('null');
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        AbacusTransferNGInboundRest.InboundResponse out = AbacusTransferNGInboundRest.handlePost();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals('error', out.status);
    }

    @IsTest
    static void scalarPayloadReturns400() {
        RestRequest req = new RestRequest();
        req.headers.put('Idempotency-Key', 'scalar-payload-001');
        req.requestBody = Blob.valueOf('{"type":"Currency Import","payload":"not-an-object"}');
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        AbacusTransferNGInboundRest.InboundResponse out = AbacusTransferNGInboundRest.handlePost();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals('error', out.status);
    }

    @IsTest
    static void retryOfFailedDeliveryReprocessesSameRow() {
        // First delivery fails (missing abacusDocumentNr) and commits a Failed audit row.
        RestRequest req = new RestRequest();
        req.headers.put('Idempotency-Key', 'si-retry-001');
        req.requestBody = Blob.valueOf('{"type":"Supplier Invoice Import","payload":{}}');
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        AbacusTransferNGInboundRest.InboundResponse firstOut = AbacusTransferNGInboundRest.handlePost();
        System.assertEquals(500, RestContext.response.statusCode);
        System.assertEquals('failed', firstOut.status);

        // Mule retries the same key with a corrected payload: the Failed row is reprocessed,
        // not reported as a duplicate.
        RestRequest retry = new RestRequest();
        retry.headers.put('Idempotency-Key', 'si-retry-001');
        retry.requestBody = Blob.valueOf('{"type":"Supplier Invoice Import","payload":{"abacusDocumentNr":"AB-4711"}}');
        retry.httpMethod = 'POST';
        RestContext.request = retry;
        RestContext.response = new RestResponse();
        AbacusTransferNGInboundRest.InboundResponse retryOut = AbacusTransferNGInboundRest.handlePost();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals('sent', retryOut.status);
        System.assertEquals(firstOut.abacusTransferNGId, retryOut.abacusTransferNGId,
            'retry must reuse the Failed audit row');
        AbacusTransferNG__c row = [
            SELECT Status__c, LastError__c, SupplierInvoice__c
            FROM AbacusTransferNG__c WHERE Id = :retryOut.abacusTransferNGId
        ];
        System.assertEquals('Sent', row.Status__c);
        System.assertEquals(null, row.LastError__c);
        System.assertNotEquals(null, row.SupplierInvoice__c);
        System.assertEquals(1, [SELECT COUNT() FROM SupplierInvoice__c WHERE AbacusDocumentNr__c = 'AB-4711']);
    }

    @IsTest
    static void supplierInvoiceImportWithoutDocNrReturns500() {
        RestRequest req = new RestRequest();
        req.headers.put('Idempotency-Key', 'si-bad-001');
        req.requestBody = Blob.valueOf('{"type":"Supplier Invoice Import","payload":{}}');
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        AbacusTransferNGInboundRest.InboundResponse out = AbacusTransferNGInboundRest.handlePost();

        System.assertEquals(500, RestContext.response.statusCode);
        System.assertEquals('failed', out.status);
        AbacusTransferNG__c row = [SELECT Status__c, LastError__c FROM AbacusTransferNG__c WHERE Id = :out.abacusTransferNGId];
        System.assertEquals('Failed', row.Status__c);
    }

    @IsTest
    static void currencyImportLogsRowOnly() {
        RestRequest req = new RestRequest();
        req.headers.put('Idempotency-Key', 'curr-001');
        req.requestBody = Blob.valueOf('{"type":"Currency Import","payload":{"isoCode":"EUR","exchangeRate":0.92}}');
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        AbacusTransferNGInboundRest.InboundResponse out = AbacusTransferNGInboundRest.handlePost();

        System.assertEquals('sent', out.status);
        AbacusTransferNG__c row = [SELECT Status__c, Direction__c, InterfaceType__c FROM AbacusTransferNG__c WHERE Id = :out.abacusTransferNGId];
        System.assertEquals('Sent', row.Status__c);
        System.assertEquals('Inbound', row.Direction__c);
        System.assertEquals('Currency Import', row.InterfaceType__c);
    }
}
