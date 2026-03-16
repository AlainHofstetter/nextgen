public with sharing class SIMController 
{ 
    private ApexPages.StandardController controller;
    private String url;
    private SIMSettings__c m_Settings = SIMSettings__c.getInstance('SIMSettings');
 
    public SIMController(ApexPages.StandardController pController) 
    {
      this.controller = pController;
    }
                         
    public String getUrl() 
    {
        this.url = m_Settings.SIMURL__c + '/proxy.aspx?objecttype=CRMREQUEST&tablename=' + this.controller.getRecord().getsObjectType().getDescribe().getName() + '&recordid=' + controller.getRecord().get('Id');
        if(m_Settings.SIMInstanceName__c != null)
        {
            this.url += '&instancename=' + m_Settings.SIMInstanceName__c;
        }
        String lang = UserInfo.getLanguage();
        lang = lang.subString(0, 2);        
        this.url += '&LANG=' + lang;
        Cookie simactive = ApexPages.currentPage().getCookies().get('simactive');
        if(simactive != null)
        {
            String ckval = simactive.getValue();
            List<String> lstCkval = ckval.split('|', 2);
            if(lstCkval.Size() == 2)
            {
                System.debug('SessionId: '+lstCkval[0]);
                System.debug('CurrentPage: '+lstCkval[1]);
                if(lstCkval[0] != UserInfo.GetSessionId() || lstCkval[1] != ApexPages.currentPage().getParameters().get('id'))
                { 
                    simactive = null;
                }
            }
            else
                simactive = null;
        }
        if(simactive == null)
        {
            System.debug('Request new token');
            // Call URL for token… (webservice op basis van url/login/pwd 
            // .. webservice
            string username = m_Settings.SIMUser__c;
            string pwd = m_Settings.SIMPassword__c;
            AuthenticationAPI.AuthenticationSoap ss = new AuthenticationAPI.AuthenticationSoap();
            ss.endpoint_x = m_Settings.SIMAuthURL__c;
            AuthenticationAPI.GetSecurityTokenResponse_element res = ss.GetSecurityToken(username, pwd, UserInfo.getUserName());
            if(0 == res.GetSecurityTokenResult)
            {
                this.url += '&token=' + res.token; 
                simactive = new Cookie('simactive',UserInfo.GetSessionId() + '|' + ApexPages.currentPage().getParameters().get('id'),null,-1,false);              
                ApexPages.currentPage().setCookies(new Cookie[]{simactive});          
            }
            else
            {
                System.debug(Logginglevel.ERROR, res.error);            
            }
        }
        else
            System.debug('Reuse existing token');
        //System.debug(this.url);
        return this.url;
    }
    
    public String getSimUrl()
    {
      return m_Settings.SIMURL__c;   
    }
   
    /*public void fillSettings()
    {
        if(m_Settings == null)
        {
            m_Settings = SIMSettings__c.getInstance('SIMSettings');
            if(m_Settings == null)
            {
                SIMSettings__c settings = new SIMSettings__c(Name='SIMSettings', SIMAuthURL__c = 'https://<simserver>/automation/Authentication.asmx',
                    SIMInstanceName__c = '<siminstancename>', SIMPassword__c = '<simpwd>', SIMURL__c = 'https://<simserver>/simweb', SIMUser__c = '<simuser>');
                insert settings;    
                m_Settings = SIMSettings__c.getInstance('SIMSettings');
            }        
        }
    }*/
    
    /* public static testMethod void TestUrl()  */
    /* {         */
    /*     Contact ct = new Contact(); */
    /*     ApexPages.StandardController sc = new ApexPages.StandardController(ct); */
    /*     SIMController controller = new SIMController(sc);  */
    /*     String url = controller.getUrl();   */
    /*     System.Debug(url);    */
    /* }     */
    /*  */
    /* public static testMethod void TestSimUrl()  */
    /* {                 */
    /*     Contact ct = new Contact(); */
    /*     ApexPages.StandardController sc = new ApexPages.StandardController(ct); */
    /*     SIMController controller = new SIMController(sc);  */
    /*     String simurl = controller.getSimUrl();   */
    /*     System.Debug(simurl);        */
    /* }     */
    
}