//
//  AppDelegate.swift
//  ThingFroce
//
//  Created by Hari Kolasani on 2/21/16.
//  Copyright © 2016 BlueCloud Systems. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    var oauth2: OAuth2CodeGrant?
    
    var awsIoTConnectionManager:AWSIoTConnectionManager?
    
    var credentialsProvider:AWSCognitoCredentialsProvider?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
         NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AppDelegate.tokenExpired), name: "tokenExpired", object: nil)
        
        self.authorize()
        
        return true
    }
    
    func authorize() {
        
        let settings = [
            "client_id": SFDCClientId,
            "client_secret": SFDCClientSecret,
            "authorize_uri": SFDCAuthURL,
            "token_uri": SFDCTokenURL,
            "scope": SFDCScopes,
            "redirect_uris": [SFDCCallbackURL],
            "keychain": true,     // if you DON'T want keychain integration
            "title": "SFDC OAuth",  // optional title to show in views
            "secret_in_body":true
            ] as OAuth2JSON            // the "as" part may or may not be needed
        
        oauth2 = OAuth2CodeGrant(settings: settings)
        
        oauth2!.authConfig.authorizeEmbedded = false
        
        oauth2!.onAuthorize = { parameters in
           
            print("Did authorize with parameters: \(parameters)")
            print("Access Token: "  +  self.oauth2!.accessToken!)
            print("Refresh Token: "  + self.oauth2!.refreshToken!)
            print("OpenId Token in OnAuthorize: " + self.oauth2!.openIdToken!)
           
            
            let openIdToken = self.oauth2!.openIdToken!
            
            if(self.awsIoTConnectionManager == nil) {
                self.awsIoTConnectionManager = AWSIoTConnectionManager()
            }
            
            self.awsIoTConnectionManager!.doSomeIotStuff(openIdToken)
        }
        
        oauth2!.onFailure = { error in        // `error` is nil on cancel
            if nil != error {
                print("Authorization went wrong: \(error.debugDescription)")
            }
        }
        
        oauth2!.authorize()
    }
    
    func tokenExpired() {
        
        self.oauth2?.forgetTokens()
        
        self.authorize()
    }
    
    func application(application: UIApplication,openURL url: NSURL,sourceApplication: String?,annotation: AnyObject) -> Bool {
        
        oauth2!.handleRedirectURL(url)
        
        return true
    }
}

