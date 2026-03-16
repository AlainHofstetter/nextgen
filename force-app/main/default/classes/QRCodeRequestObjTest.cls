/**
 * Tests the functionality of QRCodeRequestObj.
 * 
 * @author Jorge Valdes jorge@inspireai.com
 * @since Feb 2025
 */
@isTest
private class QRCodeRequestObjTest {
    
    @isTest
    static void testToJson() {
        // Create and populate a QRCodeRequestObj instance.
        QRCodeRequestObj req = new QRCodeRequestObj();
        
        // Set up CreditorInformation.
        req.creditorInformation = new QRCodeRequestObj.CreditorInformation();
        req.creditorInformation.iban = 'CH9300762011623852957';
        req.creditorInformation.creditor = new QRCodeRequestObj.Creditor();
        req.creditorInformation.creditor.addressType = 'STRUCTURED';
        req.creditorInformation.creditor.name = 'Test Creditor';
        req.creditorInformation.creditor.streetName = 'Main Street';
        req.creditorInformation.creditor.postalCode = '8000';
        req.creditorInformation.creditor.city = 'Zurich';
        req.creditorInformation.creditor.country = 'CH';
        
        // Set up UltimateDebtor.
        req.ultimateDebtor = new QRCodeRequestObj.UltimateDebtor();
        req.ultimateDebtor.addressType = 'STRUCTURED';
        req.ultimateDebtor.name = 'Test Debtor';
        req.ultimateDebtor.streetName = 'Another Street';
        req.ultimateDebtor.postalCode = '3000';
        req.ultimateDebtor.city = 'Bern';
        req.ultimateDebtor.country = 'CH';
        
        // Set up PaymentAmountInformation.
        req.paymentAmountInformation = new QRCodeRequestObj.PaymentAmountInformation();
        req.paymentAmountInformation.amount = 123.45;
        req.paymentAmountInformation.currency_z = 'CHF';
        
        // Set up PaymentReference.
        req.paymentReference = new QRCodeRequestObj.PaymentReference();
        req.paymentReference.additionalInformation = new QRCodeRequestObj.AdditionalInformation();
        req.paymentReference.additionalInformation.unstructuredMessage = 'Test Message';
        
        // Serialize to JSON using the toJson() method.
        String jsonOutput = req.toJson();
        System.debug('Generated JSON: ' + jsonOutput);
        
        // Verify the reserved keyword is replaced: "currency_z" should not appear.
        Assert.isFalse(jsonOutput.contains('currency_z'), 'JSON should not contain "currency_z".');
        Assert.isTrue(jsonOutput.contains('"currency":"CHF"'), 'JSON should contain "currency" with the value "CHF".');
        
        // Optionally, deserialize the JSON to verify the overall structure.
        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(jsonOutput);
        Assert.isTrue(jsonMap.containsKey('creditorInformation'), 'Missing creditorInformation key.');
        Assert.isTrue(jsonMap.containsKey('ultimateDebtor'), 'Missing ultimateDebtor key.');
        Assert.isTrue(jsonMap.containsKey('paymentAmountInformation'), 'Missing paymentAmountInformation key.');
        Assert.isTrue(jsonMap.containsKey('paymentReference'), 'Missing paymentReference key.');
        
        // Verify nested PaymentAmountInformation details.
        Map<String, Object> paymentAmountInfo = (Map<String, Object>) jsonMap.get('paymentAmountInformation');
        Assert.areEqual(123.45, paymentAmountInfo.get('amount'), 'Amount does not match.');
        Assert.areEqual('CHF', paymentAmountInfo.get('currency'), 'Currency does not match.');
    }
}