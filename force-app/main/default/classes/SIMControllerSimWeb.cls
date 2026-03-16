public with sharing class SIMControllerSimWeb
{ 
    private ApexPages.StandardController controller;
    private String url;
    private SIMSettings__c m_Settings =  SIMSettings__c.getInstance('SIMSettings');
 
    public SIMControllerSimWeb(ApexPages.StandardController pController) 
    {
      this.controller = pController;
    }
                         
    public String getUrl() 
    {                            
        this.url = m_Settings.SIMURL__c + '/proxy.aspx?objecttype=CRMSIMWEBLOGINREQUEST';
       
        string username = m_Settings.SIMUser__c;
        string pwd = m_Settings.SIMPassword__c;
            
        // Call URL for token…
        // .. webservice
        AuthenticationAPI.AuthenticationSoap ss = new AuthenticationAPI.AuthenticationSoap();
        ss.endpoint_x = m_Settings.SIMAuthURL__c;
        AuthenticationAPI.GetSecurityTokenForIdentityResponse_element res = ss.GetSecurityTokenForIdentity(username, pwd, UserInfo.getUserName());
        if(0 == res.GetSecurityTokenForIdentityResult)
        {
           this.url += '&token=' + res.token;                    
        }
        else
        {
           System.debug(Logginglevel.ERROR, res.error);            
        }
        
        System.debug(this.url);
        return this.url;
    }
    
    public String getSimUrl()
    {
      return m_Settings.SIMURL__c;   
    }
   
   /* public static testMethod void TestSimWebUrl()  */
   /*  {         */
   /*      Contact ct = new Contact(); */
   /*      ApexPages.StandardController sc = new ApexPages.StandardController(ct); */
   /*      SIMControllerSimWeb controller = new SIMControllerSimWeb(sc);  */
   /*      String url = controller.getUrl();   */
   /*      System.Debug(url);        */
   /*  }     */
   /*  */
   /*  public static testMethod void TestSimWebSimUrl()  */
   /*  {                 */
   /*      Contact ct = new Contact(); */
   /*      ApexPages.StandardController sc = new ApexPages.StandardController(ct); */
   /*      SIMControllerSimWeb controller = new SIMControllerSimWeb(sc);  */
   /*      String simurl = controller.getSimUrl();   */
   /*      System.Debug(simurl); */
   /*  }     */
 }