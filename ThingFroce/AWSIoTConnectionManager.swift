    //
    //  AWSIoTConnectionManager
    //  ThingFroce
    //
    //  Created by Hari Kolasani on 2/21/16.
    //  Copyright © 2016 BlueCloud Systems. All rights reserved.
    //

    import UIKit
    
    class AWSIoTConnectionManager {
        
        var connected = false
        
        var credentialsProvider:AWSCognitoCredentialsProvider?
        
        //NOW Attach iOT Policy to publish some messages
        func doSomeIotStuff(openIdToken:String) {
            
            AWSLogger.defaultLogger().logLevel = AWSLogLevel.Verbose
            
            var logins = [NSObject : AnyObject]()
            logins["login.salesforce.com"] = openIdToken
            
            if(credentialsProvider == nil) {
                credentialsProvider = AWSCognitoCredentialsProvider(regionType: AwsRegion,
                                                                    identityId: nil, accountId: AWSAccountId, identityPoolId: AWSCognitoIdentityPoolId, unauthRoleArn: nil, authRoleArn: AWSCongnitoSalesforceRoleARN, logins: logins)
            }
            else {
                credentialsProvider?.logins = logins
            }
            
            let configuration = AWSServiceConfiguration(region: AwsRegion,credentialsProvider:credentialsProvider)
            
            AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
            
            let awsIoT = AWSIoT.defaultIoT()
            
            let attachPrincipalPolicyRequest = AWSIoTAttachPrincipalPolicyRequest()
            attachPrincipalPolicyRequest.policyName = PolicyName
            attachPrincipalPolicyRequest.principal = self.credentialsProvider!.identityId
            
            awsIoT.attachPrincipalPolicy(attachPrincipalPolicyRequest).continueWithBlock { (task) -> AnyObject? in
                if let error = task.error {
                    let message = error.localizedDescription
                    print("failed: \(message)")
                    
                    //RE AUTTH for an expired SFDC OpenID Token
                    self.credentialsProvider!.clearCredentials() //clears the cache.
                    
                    self.credentialsProvider!.refresh()
                            
                    NSNotificationCenter.defaultCenter().postNotificationName("tokenExpired", object: nil)
                }
                if let exception = task.exception {
                    print("failed: [\(exception)]")
                }
                print("Result: [\(task.result)]")
                if (task.exception == nil && task.error == nil)
                {
                    self.subscribeToAWSIoT()
                    
                    self.publish()  //send a message to an AWS IoT Topic
                }
                
                return nil
            }
        }
        
        //send a message to an AWS IoT Topic
        func publish() {
            
            let awsIoTData = AWSIoTData.defaultIoTData()
            
            let publishRequest = AWSIoTDataPublishRequest()
            
            publishRequest.topic = "xyz"
            publishRequest.qos = 1
            
            do {
                try publishRequest.payload  = NSJSONSerialization.dataWithJSONObject(["msg":"test from sfdc to aws IoT" + String(NSDate().timeIntervalSince1970)], options: NSJSONWritingOptions.PrettyPrinted)
            } catch let myJSONError {
                print(myJSONError)
            }
            
            awsIoTData.publish(publishRequest).continueWithBlock { (task) -> AnyObject? in
             
                dispatch_async( dispatch_get_main_queue()) {
                        print("published successfully!:")
                }
                return nil
            }
        }
        
        //list your AWS IoT things
        func subscribeToAWSIoT() {
            
            let iotDataManager = AWSIoTDataManager.defaultIoTDataManager()
            
            iotDataManager.subscribeToTopic("xyz", qos: 0, messageCallback: {
                (payload) ->Void in
                let stringValue = NSString(data: payload, encoding: NSUTF8StringEncoding)!
                
                print("Received from AWS IoT: \(stringValue)")
            } )
        }
        
        //list your AWS IoT things
        func listThings() {
            
            let awsIoT = AWSIoT.defaultIoT()
            
            awsIoT.listThings(AWSIoTListThingsRequest()).continueWithBlock { (task) -> AnyObject? in
                if let error = task.error {
                    print("failed: [\(error)]")
                }
                if let exception = task.exception {
                    print("failed: [\(exception)]")
                }
                if (task.error == nil && task.exception == nil) {
                    dispatch_async( dispatch_get_main_queue()) {
                        //let result = task.result!
                        //let json = JSON(data: result.payload as NSData!)
                        //print("worked:")
                    }
                }
                return nil
            }
        }
    }