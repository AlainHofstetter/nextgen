/**
 * Represents the payload structure for the QR Code generation API.
 * Encapsulates all required data sections for creating a QR code request.
 * 
 * @author Jorge Valdes jorge@inspireai.com
 * @since Feb 2025
 */
public with sharing class QRCodeRequestObj {
    public CreditorInformation creditorInformation;
    public UltimateDebtor ultimateDebtor;
    public PaymentAmountInformation paymentAmountInformation;
    public PaymentReference paymentReference;
    
    /**
     * Encapsulates the creditor's IBAN and associated creditor details.
     */
    public class CreditorInformation {
        public String iban;
        public Creditor creditor;
    }
    
    /**
     * Holds detailed information about the creditor.
     */
    public class Creditor {
        public String addressType;
        public String name;
        public String streetName;
        public String postalCode;
        public String city;
        public String country;
    }
    
    /**
     * Contains details about the ultimate debtor.
     */
    public class UltimateDebtor {
        public String addressType;
        public String name;
        public String streetName;
        public String postalCode;
        public String city;
        public String country;
    }
    
    /**
     * Holds the payment amount and currency.
     * Note: The currency field is stored as currency_z to avoid reserved keyword conflicts.
     */
    public class PaymentAmountInformation {
        public Decimal amount;
        public String currency_z;
    }
    
    /**
     * Encapsulates additional information regarding the payment reference.
     */
    public class PaymentReference {
        public String reference;
        public String referenceType;
        public AdditionalInformation additionalInformation;
    }
    
    /**
     * Contains any unstructured message for the payment reference.
     */
    public class AdditionalInformation {
        public String unstructuredMessage;
    }
    
    /**
     * Serializes this QRCodeRequestObj instance to a JSON string.
     * Replaces the reserved field name 'currency_z' with 'currency' in the output.
     * 
     * @return A JSON string representing this request payload.
     */
    public String toJson() {
        String jsonBody = JSON.serialize(this);
        // Replace the reserved keyword placeholder with the expected key.
        jsonBody = jsonBody.replace('"currency_z":', '"currency":');
        return jsonBody;
    }
}