/**
 * QRCodeUtilsTest is the test class for QRCodeUtils.
 * It ensures that all QR-related utility functions behave as expected.
 *
 * @author Jorge Valdés
 * @since Mar 2025
 */
@isTest
private class QRCodeUtilsTest {
    
    @isTest 
    static void testIsQrIban_Valid() {
        // Example of a valid QR-IBAN: positions 5-9 should be between 30000 and 31999.
        // For example, "CH9330000000000000000" where substring(4,9) = "30000".
        String qrIban = 'CH9330000000000000000';
        Assert.isTrue(QRCodeUtils.isQrIban(qrIban), 'Expected IBAN to be detected as a QR-IBAN.');
    }
    
    @isTest 
    static void testIsQrIban_Invalid() {
        // Example of a non-QR IBAN: positions 5-9 ("07620") are not in the QR range.
        String nonQrIban = 'CH9300762011623852957';
        Assert.areEqual(false, QRCodeUtils.isQrIban(nonQrIban), 'Expected IBAN not to be detected as a QR-IBAN.');
        
        // Test with null.
        Assert.areEqual(false, QRCodeUtils.isQrIban(null), 'Null IBAN should return false.');
    }

    @isTest 
    static void testIsQrIban_Exception() {
        // Test with random text.
        Assert.areEqual(false, QRCodeUtils.isQrIban('KJBSDKBASLIJBDLAIJBFA'), 'Null IBAN should return false.');
    }
    
    @isTest 
    static void testGenerateQrReferenceShort() {
        // Use a base string (e.g., an invoice number) for reference generation.
        String base = '25017738';
        String qrRef = QRCodeUtils.generateQrReference(base);
        Assert.areNotEqual(null, qrRef, 'QR reference should not be null.');
        Assert.areEqual(27, qrRef.length(), 'QR reference should be 27 digits long.');
        
        // Test that non-digit characters are removed.
        String baseWithNonDigits = '2501-7738';
        String qrRef2 = QRCodeUtils.generateQrReference(baseWithNonDigits);
        Assert.areEqual(27, qrRef2.length(), 'QR reference with non-digits should be 27 digits long.');
    }

    @isTest 
    static void testGenerateQrReferenceLong() {
        // Use a base string (e.g., an invoice number) for reference generation.
        String base = '545323425017738356345634563456';
        String qrRef = QRCodeUtils.generateQrReference(base);
        Assert.areNotEqual(null, qrRef, 'QR reference should not be null.');
        Assert.areEqual(27, qrRef.length(), 'QR reference should be 27 digits long.');
        
        // Test that non-digit characters are removed.
        String baseWithNonDigits = '2501-7738';
        String qrRef2 = QRCodeUtils.generateQrReference(baseWithNonDigits);
        Assert.areEqual(27, qrRef2.length(), 'QR reference with non-digits should be 27 digits long.');
    }

    @isTest 
    static void testGenerateQrReferenceException() {
        // Use a null value to verify that generateQrReference throws an IllegalArgumentException
        try {
            String qrRef = QRCodeUtils.generateQrReference(null);
            Assert.isTrue(false, 'Expected IllegalArgumentException was not thrown when base is null.');
        } catch (IllegalArgumentException e) {
            Assert.areEqual('Base reference cannot be null', e.getMessage(),
                'The exception message should be "Base reference cannot be null" when null is provided.');
        }
    }
    
    @isTest 
    static void testCleanIban() {
        String rawIban = ' CH93 3000 0000 0000 0000 ';
        String cleaned = QRCodeUtils.cleanIban(rawIban);
        Assert.areEqual('CH933000000000000000', cleaned, 'IBAN should be trimmed and spaces removed.');
    }
    
    @isTest 
    static void testGetCompanyName() {
        // Test for "gateB" cost center.
        String result = QRCodeUtils.getCompanyName('GateB something');
        Assert.areEqual('gateB AG', result, 'Expected "gateB AG" for cost center containing "GateB".');
        
        // Test for "Calydo" cost center.
        result = QRCodeUtils.getCompanyName('Calydo services');
        Assert.areEqual('Calydo AG', result, 'Expected "Calydo AG" for cost center containing "Calydo".');
        
        // Test for "HBC" cost center (HOTZ constant is defined as "HBC").
        result = QRCodeUtils.getCompanyName('HBC operations');
        Assert.areEqual('Hotz Brand Consultants AG', result, 'Expected "Hotz Brand Consultants AG" for cost center containing "HBC".');
        
        // Test for "Hilda" cost center.
        result = QRCodeUtils.getCompanyName('Hilda teams');
        Assert.areEqual('Hilda Ltd.', result, 'Expected "Hilda Ltd." for cost center containing "Hilda".');
        
        // Test for "Focusnext" cost center.
        result = QRCodeUtils.getCompanyName('Focusnext initiatives');
        Assert.areEqual('FocusNext', result, 'Expected "FocusNext" for cost center containing "Focusnext".');
        
        // Test for "Studio Victor Hotz" cost center.
        result = QRCodeUtils.getCompanyName('Studio Victor Hotz creative');
        Assert.areEqual('Studio Victor Hotz', result, 'Expected "Studio Victor Hotz" for cost center containing "Studio Victor Hotz".');
        
        // Test for an unknown cost center value.
        result = QRCodeUtils.getCompanyName('Unknown Center');
        Assert.areEqual('Brand Leadership Circle', result, 'Expected default company name for non-matching cost center.');
        
        // Test for null cost center.
        result = QRCodeUtils.getCompanyName(null);
        Assert.areEqual('Brand Leadership Circle', result, 'Expected default company name when cost center is null.');
    }
    
    @isTest static void testGetInvoiceNameLabel() {
        // Test for German language.
        String labelDe = QRCodeUtils.getInvoiceNameLabel('25017738', 'de');
        Assert.areEqual('Rechnungsnummer: 25017738', labelDe, 'Expected German invoice label.');
        
        // Test for English language.
        String labelEn = QRCodeUtils.getInvoiceNameLabel('25017738', 'en');
        Assert.areEqual('Invoice number: 25017738', labelEn, 'Expected English invoice label.');
        
        // Test when invoice document number is null.
        String labelNull = QRCodeUtils.getInvoiceNameLabel(null, 'en');
        Assert.areEqual('Invoice number: -', labelNull, 'Expected default invoice label for null document number.');
    }
}