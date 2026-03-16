public class QRBillRequestSettings {
    
    public String separatorLines;
    public String outputSize;
    public String paperFormat;
    public String billInformation;
    public boolean hasDebtor;
    
    public QRBillRequestSettings(QRBillSetting__c csSettings){
        if(csSettings != null){
            this.separatorLines = csSettings.Separator_Lines__c;
            this.outputSize = csSettings.Output_Size__c;
            this.paperFormat = csSettings.Paper_Format__c;
            this.billInformation = csSettings.Document_Format__c;
            this.hasDebtor = csSettings.Has_Debtor__c;
        }
	}
}