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
     * Determines whether the given IBAN string corresponds to a Swiss QR-IBAN.
     * A Swiss QR-IBAN must have an institution identifier (characters 5–9) between 30000 and 31999.
     *
     * @param iban The IBAN string to evaluate, may be null or shorter than 9 characters.
     * @return true if the IBAN is a valid Swiss QR-IBAN; false if null, too short, improperly formatted, or out of range.
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
     * Generates a 27-digit Swiss QR reference number by left-padding the base string to 26 digits and computing a check digit.
     *
     * @param base The base reference string (numeric invoice or order number), may contain non-digit characters.
     * @return A 27-digit QR reference string consisting of the 26-digit padded base and a modulo-10 check digit.
     * @throws IllegalArgumentException if base is null.
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
     * Cleans the provided IBAN string by trimming whitespace and removing all spaces.
     *
     * @param rawIban The raw IBAN string, potentially null or containing spaces.
     * @return The cleaned IBAN without spaces; returns an empty string if input is null.
     */
    public static String cleanIban(String rawIban) {
        if(rawIban == null) return '';
        return rawIban.trim().replace(' ', '');
    }

    /**
     * Maps a cost center identifier to a company name based on predefined keywords.
     *
     * @param costCenter The cost center string to evaluate (case-insensitive).
     * @return The matching company name; defaults to 'Brand Leadership Circle' if no match is found.
     */
    public static String getCompanyName(String costCenter) {
        String upperCostCenter = (costCenter != null) ? costCenter.toUpperCase() : '';
        if (upperCostCenter.contains(GATEB.toUpperCase())) {
            return 'GateB AG';
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
        } else {
            return 'Brand Leadership Circle';
        }
    }
    
    /**
     * Constructs a localized invoice label prefixing the invoice number based on language code.
     *
     * @param invoiceDocNr The invoice document number (Object), will be converted to string.
     * @param language The ISO language code ('de' for German); any other value defaults to English.
     * @return A string label 'Rechnungsnummer: {number}' or 'Invoice number: {number}', or '-' if number is null.
     */
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