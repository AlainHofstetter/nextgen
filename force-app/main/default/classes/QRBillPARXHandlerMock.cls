/*
*  @author Manjiri
*  @copyright PARX
*
*  21.08.2022
*
*/
global class QRBillPARXHandlerMock implements HttpCalloutMock{
   global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        //response.setBody('[codeResult=200, error=null, imgData=iVBORw0KGgoAAAANSUhEUgAABKcAAAJTCAAAAAD4OCqUAAAACXBIWXMAABYlAAAWJQFJUiTwAAAAE3RFWHRUaXRsZQBTd2lzcyBRUiBCaWxsom1XRgAAYupJREFUeNrtnQl4VcXd/ychKwkYIEBQlsumgKKxFUHFmrqitRotrbg2WrRYUeP7Ypv6thq3v1QRo1KLFvWqRYFSjdYq4HJVFNzjglKLesFQAwYIECFsYf5n5pyZM3POnHtvSEJuku/3ebh39pkzufNhzpw5vyEUgiAouUXQBRAEgVMQBEHgFARB4BS0zwqjCyAInEL/QhDGEYT+hSCMI/QvBEEYR+hfCMI4ggKFdXQIAqcgCAKnIAiCwCkIgiBwCoIgcAoKVghdAEHgFPoXgjCOIPQvBGEcoX]');
        response.setBody('{"recordId":"00v0E000005oK01QAE","imgData":"iVBORw0KGgoAAAANSUhEUgAABKcAAAJwCAAAAAB5AF0MAAAACXBIWXMAABYlAAAWJQFJUiTwAAAAE3RFWHRUaXRsZQBTd2lzcyBRUiBCaWxsom1XRgAAcv5JREFUeNrsnXlgFdX595/sCwmGECDsl80CoqKCRMUacUN/LqnSSlVsatFiRY0tttRWDaCvVBGjosWKmi4gUBS01uIaFgW1YlxQtCgXDBowQAIxhCVw3jkz58w8c+bM3JsNsjzfP+6cc+YsM5M7n5z7zJnnAUYikUgtW0CXgEQiEadIJBKJOEUikYhTJBKJRJwikUgk4hSJRCJOkUgkEnGKRCIRp0gkEok4RSKRSMQpEolEnCKRSCTiFIlEIhGnSCQ"}');
        response.setStatusCode(200);
        return response; 
    }    
}