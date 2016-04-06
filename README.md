# ThingForce

Typically Salesforce iOS Apps use Force.com platform as a back end, but there could some use cases for integrating those apps with AWS products like S3, Lambda, Dynamo or even IoT!.

In order to call the AWS APIs the iOS app needs to be authenticated with AWS. But in general the Salesforce apps are authenticated with Salesforce using OAuth. So we need AWS to honor the Salesforce authentication and luckily AWS Cognito comes into rescue by supporting OpenID based identity providers and Salesforce does support OpenID. 

This post talks some technical details around using AWS Cognito as an authentication mechanism for the iOS Apps with Salesforce as an identity provider via the OpenID Connect. 

# Flow
- Mobile App user authenticates with Salesforce using OAuth
- The App obtains the OpenId Token from Salesforce
- App passes the OpenId token to Cognito and gets AWS Access Token for using with the APIs for S3, Lambda, Dynamo or IoT depending on the AWS Policy configurations.

# Configuration
- Create a Connected App on Force.com and obtain the ClientID, Secret and Callback URL. Make sure to include 'Allow Access to OpenID' in the OAuth scopes for this connected app.
- Create a new Identity Provider for OpenID Connect in AWS IAM. Specify 'login.salesforce.com' as the provider URL and the 'clientId' of the connected app as the 'Audience'.
- Create an Identity Pool in AWS Cognito App and configure new IAM roles and select the Salesforce OpenID provider crated above.
- Configure a AWS IAM policy for the new roles created in above step. 

# The iOS App
- Use OAuth2 Swift library to perform the OAuth flow and authenticate with Salesforce.  The reason why a third party OAuth library is used instead of the Salesforce Mobile SDK is that the Salesforce Mobile SDK does not provide a way to obtain the OpenID token. It only gives you the access token to be used with the Force.com API.
- Tweak OAuth2 Swift library to add support for OpenID token. Basically to parse the token response to obtain the OpenID token and store it in the key chain. 
- Instantiate  AWSCognitoCredentialsProvider of AWS Mobile SDK using the salesforce OpenID token and obtain the AWSServiceConfiguration to call the AWS APIs.  Please refer to this sample class that uses AWS IoT API.

And one more thing! : The Salesforce OpenID expires much quicker (typically 15 minutes) compared to the access token,  and also the Salesforce OAuth flow doesn't support an auto refresh mechanism for OpenId token unlike the access token. So, the only way to refresh the OpenID token is to re-authenticate to Salesforce by re-initiating the OAuth flow.
