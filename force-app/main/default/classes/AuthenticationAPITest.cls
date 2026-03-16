@IsTest
public class AuthenticationAPITest {
    @IsTest
    static void EmptyClassTest() {
        AuthenticationAPI.GetSecurityTokenForIdentityResponse_element ss = new AuthenticationAPI.GetSecurityTokenForIdentityResponse_element();
        ss.error = '';
        AuthenticationAPI.GetSecurityTokenResponse_element zz = new AuthenticationAPI.GetSecurityTokenResponse_element();
        zz.error = '';
    }
}