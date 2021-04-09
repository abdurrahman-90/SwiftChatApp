//
//  AppDelegate.swift
//  MessengerApp
//
//  Created by Akdag on 30.03.2021.
//



// Swift
//
// AppDelegate.swift
import UIKit
import FBSDKCoreKit
import Firebase
import GoogleSignIn
import IQKeyboardManagerSwift


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate,GIDSignInDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        GIDSignIn.sharedInstance()?.clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance()?.delegate = self
      
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = false
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true


        return true
    }
          
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {

        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
        return ((GIDSignIn.sharedInstance()?.handle(url)) != nil)

    }
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard error == nil  else{
            if let error = error {
                print(error)
            }
            return
        }
        guard let email = user.profile.email ,
              let firstName = user.profile.givenName ,
              let lastName = user.profile.familyName else{return}
        
        UserDefaults.standard.set(email , forKey: "email")
        UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
        
        DatabaseManager.shared.userExist(with: email) { (exist) in
            if !exist{
                let chatUser = ChatAppUser(firstName: firstName,
                                           lastName: lastName,
                                           emailAdress: email)
                DatabaseManager.shared.insertUser(with: chatUser) { (succes) in
                    if succes {
                        // upload image
                        if user.profile.hasImage {
                            guard let url = user.profile.imageURL(withDimension: 200) else{
                                return
                            }
                            URLSession.shared.dataTask(with: url) { (data, _, _) in
                                guard let data = data else{return}
                                
                                let fileName = chatUser.profilePictureFileName
                                 StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName) { (result) in
                                    switch result {
                                    case .success(let downLoadUrl):
                                        UserDefaults.standard.set(downLoadUrl , forKey: "_profile_picture.url")
                                        print(downLoadUrl)
                                    case .failure(let error):
                                     print("System Error : \(error)")
                                    }
                                }
                            }.resume()
                         
                        }
                      
                    }
                }
            }
        }
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                          accessToken: authentication.accessToken)
        
        Firebase.Auth.auth().signIn(with: credential) { (authResault, error) in
            
            guard authResault != nil , error == nil else{return}
            
            NotificationCenter.default.post(name: .didLogInNotification, object: nil)
        }
       
    }
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        print("kullanıcı bağlantı sağladı")
    }

}
    

