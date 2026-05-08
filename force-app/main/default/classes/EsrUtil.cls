public  class EsrUtil {
    // base table to find carryover
    private final static Integer[] carryoverTable = new Integer[]{0, 9, 4, 6, 8, 2, 7, 1, 3, 5}; 
    private final static String[] arr_25 = new String[]{'d', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '{', '|', '}', '~', '…', 'ä', 'å', '‚', 'ƒ', '„', '!', '†', '#', '$', '%', '&', '\'', '(', ')', '*', '+', ',', '-', '.', '/', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ':', ';', '<', '=', '>', '?', '@', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '[', '\\', ']', '^', '_', '`', 'a', 'b', 'c'}; 
    private static Map<String,Integer> hexMap = new Map<String,Integer>();
	static {
		hexMap.put('0',0);
		hexMap.put('1',1);
		hexMap.put('2',2);
		hexMap.put('3',3);
		hexMap.put('4',4);
		hexMap.put('5',5);
		hexMap.put('6',6);
		hexMap.put('7',7);
		hexMap.put('8',8);
		hexMap.put('9',9);
		hexMap.put('A',10);
		hexMap.put('B',11);
		hexMap.put('C',12);
		hexMap.put('D',13);
		hexMap.put('E',14);
		hexMap.put('F',15);
		hexMap.put('a',10);
		hexMap.put('b',11);
		hexMap.put('c',12);
		hexMap.put('d',13);
		hexMap.put('e',14);
		hexMap.put('f',15);
	}

	public enum EsrFormat {UNFORMATTED, FORMATTED, CODE_LINE}
    
	private static string getZeros(integer num){
		string zeroPad = '';
		for(integer i =0; i< num; i++ ){
			zeroPad = zeroPad + '0';
		}	
		return zeroPad;
	}


    //JC: Updating GetESR with ChatGPT version below so that the ESRUnformatted value will include the account number (BLC-133).
    
    public static String getESR(String accNum, String merNum, Decimal invNum, Decimal amount, EsrFormat format){

    System.debug('---EsrUtil.getESR--- accNum: ' + accNum + ' merNum: ' + merNum + ' invNum: ' + invNum + ' amount: ' + amount + ' format:' + format);

    // Pieces
    String mer = onlyDigits(merNum);
    String invNumber = String.valueOf(invNum).replaceAll('[^0-9]','');  // keep digits only

    // Choose the segment immediately after Merchant:
    //  - prefer Account Number (digits only)
    //  - else amount in cents (digits only)
    String postMerchant;
    String acctDigits = onlyDigits(accNum);
    if (!String.isBlank(acctDigits)) {
        postMerchant = acctDigits;
    } else {
        postMerchant = amountToCentsDigits(amount); // e.g., 123.45 -> "12345"
    }

    // Build the 26-digit body: [mer][postMerchant][zeros][invNumber]
    Integer bodyTargetLen = 26;
    Integer used = mer.length() + postMerchant.length() + invNumber.length();
    if (used > bodyTargetLen) {
        // Defensive: if it doesn't fit, fail fast with a clear message (or truncate if that's your policy)
        throw new AuraHandledException(
            'ESR reference parts exceed length: mer=' + mer.length() + ', chosen=' + postMerchant.length() + ', inv=' + invNumber.length()
            + ' > ' + bodyTargetLen + '. Adjust segment sizes or input lengths.'
        );
    }
    Integer zeroPadLength = bodyTargetLen - used;

    String baseESR = mer + postMerchant + getZeros(zeroPadLength) + invNumber;
    String esrWithCheck = baseESR + String.valueOf(getCheckDigit(baseESR));

    if (format == EsrFormat.UNFORMATTED){
        return esrWithCheck;
    }

    if (format == EsrFormat.FORMATTED){
        // keep your existing 2-5-5-5-5-5 grouping (total 27 incl checksum)
        String[] vals = new String[]{
            esrWithCheck.substring(0,2),
            esrWithCheck.substring(2,7),
            esrWithCheck.substring(7,12),
            esrWithCheck.substring(12,17),
            esrWithCheck.substring(17,22),
            esrWithCheck.substring(22,27)
        };
        return String.format('{0} {1} {2} {3} {4} {5}', vals);
    }

    if (format == EsrFormat.CODE_LINE){
        // unchanged: your code line already includes amount & account explicitly
        String amt = String.valueOf(amount).replace('.','');
        System.debug('---EsrUtil.getESR--- amount: ' + amount+ ' amt: '+amt);

        String header = '01' + getZeros(12-(amt.length() + 2)) + amt;
        System.debug('---EsrUtil.getESR--- header: ' + header);

        String[] accParts = accNum != null ? accNum.split('-') : new String[]{};
        // Defensive defaults if accNum is blank or malformed
        String accLeft   = (accParts.size() > 0 ? accParts[0] : '');
        String accMiddle = (accParts.size() > 1 ? accParts[1] : '');
        String accRight  = (accParts.size() > 2 ? accParts[2] : '');
        String accFormatted = accLeft + getZeros(9-(accMiddle.length() + accRight.length() + 2)) + accMiddle + accRight;

        System.debug('---EsrUtil.getESR--- accFormatted: ' + accFormatted);

        String[] vals = new String[]{ header + String.valueOf(getCheckDigit(header)), esrWithCheck, accFormatted };
        System.debug('---EsrUtil.getESR--- vals: ' + vals);

        return String.format('{0}>{1}+ {2}>', vals);
    }

    // Default to unformatted
    return esrWithCheck;
}
// End of ChatGPT updated code.  
/** keep digits only (null-safe) */
private static String onlyDigits(String s) {
    return String.isBlank(s) ? '' : s.replaceAll('[^0-9]','');
}

/** convert Decimal amount to cents as digits, no sign, no dots; null -> "0" */
private static String amountToCentsDigits(Decimal amount) {
    Decimal a = (amount == null ? 0 : amount.setScale(2));
    // multiply by 100 safely and convert to positive int-like string (ESR body has only digits)
    Long cents = (Long)(a * 100); // handles big amounts better than int
    if (cents < 0) cents = -cents; // omit minus in the reference
    return String.valueOf(cents);
}
    /**
     * Return the check digit for a string of digits
     *
     */
    public static Integer getCheckDigit(String input)
    {
        // remove any non digit
        input = input.replaceAll('[^0-9]', '');
        
        // transform input string into an array of digits
        List<Integer> inputArray = new List<Integer>{};
        for (Integer i = 0; i < input.length(); i++)
        {
            inputArray.add(Integer.valueOf(input.substring(i, i+1)));
        }
        
        // get final carryover
        Integer carryover = getCarryover(inputArray);
        
        // calculate check digit
        Integer checkDigit = Math.mod((10 - carryover), 10);
        
        // return result 
        return checkDigit;
    }
    
    /**
     * Return final carryover for an array of digits
     *
     */
    private static Integer getCarryover(Integer[] input)
    {
        // loop array
        Integer carryover = 0;
        for (Integer i = 0; i < input.size(); i++)
        {
            // select correct position in carryover table
            carryover = carryoverTable[Math.mod((carryover + input.get(i)), 10)];
        }
        
        // return final carryover
        return carryover;
    }
}