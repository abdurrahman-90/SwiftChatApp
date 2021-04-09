//
//  LoginViewController.swift
//  MessengerApp
//
//  Created by Akdag on 30.03.2021.
//


import UIKit
import Firebase
import JGProgressHUD
import FBSDKLoginKit
import GoogleSignIn


class LoginViewController: UIViewController {
    private let spinner = JGProgressHUD(style: .dark)
    private let scrollView : UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    private let imageView : UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
        
    }()
    private let emailText : UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email Adress"
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
    private let password : UITextField = {
        let password = UITextField()
        password.autocapitalizationType = .none
        password.autocorrectionType = .no
        password.returnKeyType = .continue
        password.layer.cornerRadius = 12
        password.layer.borderWidth = 1
        password.layer.borderColor = UIColor.lightGray.cgColor
        password.placeholder = "Password"
        password.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        password.leftViewMode = .always
        password.backgroundColor = .secondarySystemBackground
        password.isSecureTextEntry = true
        return password
    }()
    private let loginBtn : UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 11
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20 , weight : .bold)
        return button
    }()
    private let loginButton : FBLoginButton = {
        let button = FBLoginButton()
        button.layer.cornerRadius = 11
        button.permissions = ["public_profile","email"]
        return button
    }()
    private let googlesignInBtn = GIDSignInButton()
    
    private var loginObserver : NSObjectProtocol?


    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification,
                                                               object: nil,
                                                               queue: .main,
                                                               using: { [weak self] _ in
                                                                guard let strongSelf = self else{return}
                                                                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
                                                               })
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance().signIn()
        
        title = "Log In"
        loginButton.delegate = self
        
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(didTapRegister))
        loginBtn.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        //Delegate
        emailText.delegate = self
        password.delegate = self
        // Add SubView
        view.addSubview(scrollView)
        scrollView.addSubview(emailText)
        scrollView.addSubview(password)
        scrollView.addSubview(imageView)
        scrollView.addSubview(loginBtn)
        loginButton.center = view.center
        scrollView.addSubview(loginButton)
        scrollView.addSubview(googlesignInBtn)
    }
    deinit {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.width / 3
        imageView.frame = CGRect(x: (scrollView.width - size) / 2,
                                 y: 80,
                                 width: size,
                                 height: size)
        
        emailText.frame = CGRect(x:30,
                                 y: imageView.bottom + 10,
                                 width: scrollView.width - 60,
                                 height: 52)
        password.frame = CGRect(x:30,
                                y: emailText.bottom + 10,
                                width: scrollView.width - 60,
                                height: 52)
        loginBtn.frame = CGRect(x:30,
                                y: password.bottom + 10,
                                width: scrollView.width - 60,
                                height: 52)
        loginButton.frame = CGRect(x:30,
                                   y: loginBtn.bottom + 10,
                                   width: scrollView.width - 60,
                                   height: 52)
        
        loginButton.frame.origin.y = loginBtn.bottom + 20
        
        googlesignInBtn.frame = CGRect(x:30,
                                       y: loginButton.bottom + 10,
                                       width: scrollView.width - 60,
                                       height: 52)
    }
    @objc func didTapRegister(){
        let vc = RegisterViewController()
        vc.title = "Create New Account"
        navigationController?.pushViewController(vc, animated: false)
    }
    @objc private func loginButtonTapped(){
        emailText.resignFirstResponder()
        password.resignFirstResponder()
        
        guard let email = emailText.text ,
              let password = password.text,
              !email.isEmpty,
              !password.isEmpty ,
              password.count >= 6 else {
            alertLoginError()
            return
            
        }
        spinner.show(in: view)
        
        //Firebase Log IN
        Firebase.Auth.auth().signIn(withEmail: email, password: password) {[weak self] (AuthDataResult, error) in
            guard let strongSelf = self else {return}
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            guard let result = AuthDataResult , error == nil  else {
                return
            }
           
           
            let user = result.user
            let safeEmail = DatabaseManager.safeEmail(emailAdress: email)
            DatabaseManager.shared.getDataFor(path: safeEmail, completion: { result in
                switch result {
                case .success(let data):
                    guard let userData = data as? [String:Any],
                          let firstName = userData["first_Name"] as? String,
                          let lastName = userData["last_Name"] as? String else {
                        return
                    }
                    UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                case .failure(let error):
                    print("\(error)")
                }
                
            })
            
            UserDefaults.standard.set(email , forKey: "email")
            
            print("kullanıcı giriş yaptı\(user)")
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        }
        
    }
    func alertLoginError(){
        let alert = UIAlertController(title: "Yanlış", message: "Lütfen bilgilerinizi Kontrol ediniz", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .cancel
                                      , handler: nil))
        self.present(alert, animated: true, completion: nil)
        
    }
    
}
extension LoginViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailText {
            password.becomeFirstResponder()
        }else if textField == password {
            loginButtonTapped()
        }
        return true
    }
}

extension LoginViewController : LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        //no operation
    }
    
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            print("kullanıcı giriş yaparken hata oluştu")
            return
        }

        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                         parameters: ["fields" : "email , first_name , last_name , picture.type(large)"],
                                                         tokenString: token,
                                                         version: nil,
                                                         httpMethod: .get)
        facebookRequest.start { (_, result, error) in
            guard let result = result as? [String : Any] , error == nil else{
               
                return
            }
            print(result)
            

            guard let firstName = result["first_name"] as? String ,
                  let lastName = result["last_name"] as? String,
                  let email = result["email"] as? String,
                  let picture = result["picture"] as? [String : Any],
                  let data = picture["data"] as? [String : Any],
                  let pictureUrl = data["url"] as? String
                  else{ return}

            UserDefaults.standard.set(email , forKey: "email")
            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")

            DatabaseManager.shared.userExist(with: email) { (exist) in
                if !exist{
                    let chatUser = ChatAppUser(firstName: firstName,
                                               lastName: lastName,
                                               emailAdress: email)
                    
                    UserDefaults.standard.set(email , forKey: "email")
                    

                    DatabaseManager.shared.insertUser(with: chatUser) { (succes) in
                        if succes {
                             guard let url = URL(string: pictureUrl) else{return}
                            print("facebook tan profile resmi indiriliyor")
                             URLSession.shared.dataTask(with: url) { (data, _, _) in
                                 guard let data = data else{return}
                                print("resim yüklendi")
                                 let fileName = chatUser.profilePictureFileName
                                 StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName) { (result) in
                                     switch result {
                                     case .success(let downLoadUrl):
                                         UserDefaults.standard.set(downLoadUrl , forKey: "profile_picture_url")
                                         print(downLoadUrl)
                                     case .failure(let error):
                                       print("Storage Manager Error : \(error)")
                                     }
                                 }
                             }.resume()

                        }
                    }
                }
            }
            
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            
            Firebase.Auth.auth().signIn(with: credential) {[weak self] (AuthDataResult, error) in
                guard let strongSelf = self else{return}
                guard AuthDataResult != nil , error == nil else {
                    print("Facebook la giriş başarısız")
                    return
                }
               
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
   
    }
    

}
