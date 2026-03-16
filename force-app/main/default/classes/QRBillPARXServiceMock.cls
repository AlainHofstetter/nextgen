@isTest
global class QRBillPARXServiceMock implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest request){
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"recordId":"00v0E000005oK01QAE","imgData":"iVBORw0KGgoAAAANSUhEUgAABKcAAAJwCAAAAAB5AF0MAAAACXBIWXMAABYlAAAWJQFJUiTwAAAAE3RFWHRUaXRsZQBTd2lzcyBRUiBCaWxsom1XRgAAcv5JREFUeNrsnXlgFdX595/sCwmGECDsl80CoqKCRMUacUN/LqnSSlVsatFiRY0tttRWDaCvVBGjosWKmi4gUBS01uIaFgW1YlxQtCgXDBowQAIxhCVw3jkz58w8c+bM3JsNsjzfP+6cc+YsM5M7n5z7zJnnAUYikUgtW0CXgEQiEadIJBKJOEUikYhTJBKJRJwikUgk4hSJRCJOkUgkEnGKRCIRp0gkEok4RSKRSMQpEolEnCKRSCTiFIlEIhGnSCQ"}');
        response.setStatusCode(200);
        return response;         
    }
}