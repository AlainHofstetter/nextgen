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

	public static string getESR(string accNum, string merNum, decimal invNum, decimal amount, EsrFormat format){

		string invNumber = string.valueOf(invNum);
		integer zeroPadLength = 26 - (merNum.length() + invNumber.length());

		string baseESR = merNum + getZeros(zeroPadLength) + invNumber;
		string esrWithCheck = baseESR + string.valueOf(getCheckDigit(baseESR));

		if(format == EsrFormat.UNFORMATTED){
			return esrWithCheck;
		}

		if(format == EsrFormat.FORMATTED){
			string[] vals = new string[]{esrWithCheck.substring(0,2), esrWithCheck.substring(2,7), esrWithCheck.substring(7,12), esrWithCheck.substring(12,17), esrWithCheck.substring(17,22), esrWithCheck.substring(22,27)};
			return string.Format('{0} {1} {2} {3} {4} {5}', vals);
		}

		if(format == EsrFormat.CODE_LINE){
			string amt = string.valueOf(amount).replace('.','');

			string header = '01' + getZeros(12-(amt.length() + 2)) + amt;

			string[] accParts = accNum.split('-');
			string accFormatted = accParts[0] + getZeros(9-(accParts[1].length() + accParts[2].length() + 2)) + accParts[1] + accParts[2];

			string[] vals = new string[]{header + getCheckDigit(header),esrWithCheck,accFormatted};
			return string.Format('{0}>{1}+ {2}>', vals);
		}

		//if we get here then return the unformatted version
		return esrWithCheck;
		
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