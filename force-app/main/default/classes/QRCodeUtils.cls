/**
 * QRCodeUtils is responsible for QR-related utility functions.
 * It provides methods for:
 *   - Checking if an IBAN is a QR-IBAN.
 *   - Generating a structured QR reference number based on a base string.
 *   - Cleaning an IBAN string.
 *
 * This class adheres to the Swiss Implementation Guidelines for QR-bills.
 *
 * @author Jorge Valdés
 * @since Mar 2025
 * @documentation https://docs.qr-invoice.ch/latest/getting_started/basics.html
 */
public with sharing class QRCodeUtils {
    // Constants for company name mapping.
    private static final String CALYDO = 'Calydo';
    private static final String GATEB = 'GateB';
    private static final String HOTZ = 'HBC';
    private static final String HILDA = 'Hilda';
    private static final String FOCUSNEXT = 'Focusnext';
    private static final String STUDIO_HOTZ = 'Studio Victor Hotz';
    private static final String HOM = 'HOM';

    // Lookup table as defined by the Swiss Implementation Guidelines
    private static final Integer[][] TABLE = new Integer[][]{
        new Integer[]{0, 9, 4, 6, 8, 2, 7, 1, 3, 5},
        new Integer[]{9, 4, 6, 8, 2, 7, 1, 3, 5, 0},
        new Integer[]{4, 6, 8, 2, 7, 1, 3, 5, 0, 9},
        new Integer[]{6, 8, 2, 7, 1, 3, 5, 0, 9, 4},
        new Integer[]{8, 2, 7, 1, 3, 5, 0, 9, 4, 6},
        new Integer[]{2, 7, 1, 3, 5, 0, 9, 4, 6, 8},
        new Integer[]{7, 1, 3, 5, 0, 9, 4, 6, 8, 2},
        new Integer[]{1, 3, 5, 0, 9, 4, 6, 8, 2, 7},
        new Integer[]{3, 5, 0, 9, 4, 6, 8, 2, 7, 1},
        new Integer[]{5, 0, 9, 4, 6, 8, 2, 7, 1, 3}
    };
    
    /**
     * Returns true if the given IBAN is a QR-IBAN.
     * For Swiss QR-IBANs, the institution identifier (positions 5 to 9)
     * must fall in the range 30000 to 31999.
     *
     * @param iban The IBAN to check.
     * @return Boolean indicating if the IBAN is a QR-IBAN.
     */
    public static Boolean isQrIban(String iban) {
        if (iban == null || iban.length() < 9) {
            return false;
        }
        try {
            // Positions 5 to 9 represent the institution ID.
            String institutionIdStr = iban.substring(4, 9);
            Integer institutionId = Integer.valueOf(institutionIdStr);
            return institutionId >= 30000 && institutionId <= 31999;
        } catch(Exception e) {
            return false;
        }
    }
    
    /**
     * Generates a structured QR reference (27 digits) given a base string.
     * The base string will be left-padded with zeros to reach 26 digits.
     * The check digit is computed using the modulo 10 recursive algorithm.
     *
     * @param base The base string (usually a numeric invoice or order number).
     * @return A 27-digit QR reference string.
     */
    public static String generateQrReference(String base) {
        if (base == null) {
            throw new IllegalArgumentException('Base reference cannot be null');
        }
        // Remove any non-digit characters.
        String baseDigits = base.replaceAll('\\D', '');
        
        // Left-pad to 26 digits.
        while (baseDigits.length() < 26) {
            baseDigits = '0' + baseDigits;
        }
        if (baseDigits.length() > 26) {
            baseDigits = baseDigits.right(baseDigits.length() - (baseDigits.length() - 26));
        }
        
        // Calculate the check digit using the modulo 10 recursive algorithm.
        Integer carry = 0;
        for (Integer i = 0; i < baseDigits.length(); i++) {
            Integer digit = Integer.valueOf(baseDigits.substring(i, i + 1));
            carry = TABLE.get(carry).get(digit);
        }
        
        Integer checkDigit = (10 - carry);
        if (checkDigit == 10) {
            checkDigit = 0;
        }
        
        return baseDigits + String.valueOf(checkDigit);
    }
    
    /**
     * Cleans the provided IBAN by trimming spaces.
     *
     * @param rawIban The raw IBAN string.
     * @return A trimmed IBAN without spaces.
     */
    public static String cleanIban(String rawIban) {
        if(rawIban == null) return '';
        return rawIban.trim().replace(' ', '');
    }

    // Helper method to determine the company name based on the cost center.
    public static String getCompanyName(String costCenter) {
        String upperCostCenter = (costCenter != null) ? costCenter.toUpperCase() : '';
        if (upperCostCenter.contains(GATEB.toUpperCase())) {
            return 'gateB AG';
        } else if (upperCostCenter.contains(CALYDO.toUpperCase())) {
            return 'Calydo AG';
        } else if (upperCostCenter.contains(HOTZ.toUpperCase())) {
            return 'Hotz Brand Consultants AG';
        } else if (upperCostCenter.contains(HILDA.toUpperCase())) {
            return 'Hilda Ltd.';
        } else if (upperCostCenter.contains(FOCUSNEXT.toUpperCase())) {
            return 'FocusNext';
        } else if (upperCostCenter.contains(STUDIO_HOTZ.toUpperCase())) {
            return STUDIO_HOTZ;
        } else if (upperCostCenter.contains(HOM.toUpperCase())) {
            return 'House of Manus AG';
        } else {
            return 'Brand Leadership Circle';
        }
    }
    
    // Helper method to generate the invoice name label.
    public static String getInvoiceNameLabel(Object invoiceDocNr, String language) {
        String label;
        label = (language == 'de') ? 'Rechnungsnummer: ' : 'Invoice number: ';
        
        if (invoiceDocNr != null) {
            label += String.valueOf(invoiceDocNr);
        } else {
            label += '-';
        }
        return label;
    }

}