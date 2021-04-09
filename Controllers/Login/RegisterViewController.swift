//
//  RegisterViewController.swift
//  MessengerApp
//
//  Created by Akdag on 30.03.2021.
//

import UIKit
import Firebase
import JGProgressHUD

class RegisterViewController: UIViewController {
 
    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView : UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
     private let imageView : UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.circle")
        imageView.tintColor = .gray
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        return imageView
        
    }()
    private let firstName : UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "First Name"
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    private let lastName : UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Last Name"
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
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
    private let RegisterButton : UIButton = {
        let button = UIButton()
        button.setTitle("Register", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 11
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20 , weight : .bold)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Register"

        view.backgroundColor = .secondarySystemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .plain, target: self, action: #selector(didTapRegister))
        RegisterButton.addTarget(self,
                           action: #selector(loginButtonTapped),
                           for: .touchUpInside)
        // add subview
        view.addSubview(scrollView)
        scrollView.addSubview(emailText)
        scrollView.addSubview(password)
        scrollView.addSubview(imageView)
        scrollView.addSubview(RegisterButton)
        scrollView.addSubview(firstName)
        scrollView.addSubview(lastName)
      
        //delegate
        
        emailText.delegate = self
        password.delegate = self
        
        //GesturRecognizer
        imageView.isUserInteractionEnabled = true
        scrollView.isUserInteractionEnabled = true
        
        let gesture = UITapGestureRecognizer(target: self,
                                             action: #selector(didTapchangeProfile))
        imageView.addGestureRecognizer(gesture)
        
        
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.width / 3
        imageView.frame = CGRect(x: (scrollView.width - size) / 2,
                                 y: 80,
                                 width: size,
                                 height: size)
        
        imageView.layer.cornerRadius = imageView.width / 2.0
        
        firstName.frame = CGRect(x:30,
                                 y: imageView.bottom + 10,
                                 width: scrollView.width - 60,
                                 height: 52)
        lastName.frame = CGRect(x:30,
                                 y: firstName.bottom + 10,
                                 width: scrollView.width - 60,
                                 height: 52)
        emailText.frame = CGRect(x:30,
                                 y: lastName.bottom + 10,
                                 width: scrollView.width - 60,
                                 height: 52)
        password.frame = CGRect(x:30,
                                 y: emailText.bottom + 10,
                                 width: scrollView.width - 60,
                                 height: 52)
        RegisterButton.frame = CGRect(x:30,
                                 y: password.bottom + 10,
                                 width: scrollView.width - 60,
                                 height: 52)
        
    }
    @objc func didTapchangeProfile(){
       presentPhotoActionSheet()
        
    }
    @objc private func loginButtonTapped(){
        emailText.resignFirstResponder()
        password.resignFirstResponder()
        firstName.resignFirstResponder()
        lastName.resignFirstResponder()
        
        
        guard let email = emailText.text ,
              let password = password.text,
              let firstNamefield = firstName.text ,
              let lastNamefield = lastName.text,
              !email.isEmpty,
              !password.isEmpty ,
              !firstNamefield.isEmpty,
              !lastNamefield.isEmpty,
              password.count >= 6 else {
                self.alertLoginError(message: "Bilgileri Kontrol Ediniz")
            return
        }
        // Firebase Log In
        DatabaseManager.shared.userExist(with: email) { [weak self] (exists) in
            guard let strongSelf = self else {return}
            
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            guard !exists else {
                strongSelf.alertLoginError(message: "Kullanıcı mail adresi mevcut")
                return }
        }
        Firebase.Auth.auth().createUser(withEmail: email, password: password) {[weak self] (AuthDataResult, error) in
            
            guard let strongSelf = self else {return} 
            
            guard AuthDataResult != nil, error == nil else {
                return
            }
            UserDefaults.standard.setValue(email, forKey: "email")
            UserDefaults.standard.setValue("\(strongSelf.firstName) \(strongSelf.lastName)", forKey: "name")
            
            let chatUser = ChatAppUser(firstName: firstNamefield,
                                       lastName: lastNamefield,
                                       emailAdress: email)
            DatabaseManager.shared.insertUser(with: chatUser, completion: { succes in
                if succes {
                    
                    guard let image =  strongSelf.imageView.image,
                          let data = image.pngData() else{
                        return
                    }
                    let fileName = chatUser.profilePictureFileName
                    StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName, completion: { result in
                        switch result {
                        case .success(let downloadUrl):
                            UserDefaults.standard.set(downloadUrl , forKey: "profile_picture_url")
                        case .failure(let error):
                            print("storage Manager error : \(error)")
                        }
                    })
                }else{
                    print("please try again")
                }
            })
            
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        }
        
        
  }
    func alertLoginError(message :String){
        let alert = UIAlertController(title: "Yanlış",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .cancel
                                      , handler: nil))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    @objc private func didTapRegister() {
        let vc = RegisterViewController()
        vc.title = "Create New Account"
        navigationController?.pushViewController(vc, animated: true)
        
        
    }
    

 
}
extension RegisterViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailText {
            password.becomeFirstResponder()
        }else if textField == password {
            loginButtonTapped()
        }
        return true
    }
}
extension RegisterViewController : UIImagePickerControllerDelegate,UINavigationControllerDelegate {
   
    func presentPhotoActionSheet() {
        let action = UIAlertController(title: "Profil Resmi",
                                       message: "Profil Resmi Seçiniz",
                                       preferredStyle: .actionSheet)
        action.addAction(UIAlertAction(title: "Cancel",
                                       style: .cancel,
                                       handler: nil))
        action.addAction(UIAlertAction(title: "Fotoğraf Çek",
                                       style: .default,
                                       handler: {[weak  self] _ in
                                        self?.presentCamera()
                                        
                                       }))
        action.addAction(UIAlertAction(title: "Fotoğraf Seç",
                                       style: .default,
                                       handler: {[weak self] _ in
                                        self?.presentPhoto()
                                       }))
        present(action, animated: true, completion: nil)
    }
    
    func presentCamera(){
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = .camera
        
        present(picker, animated: true, completion: nil)
    }
    func presentPhoto() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)

        guard let image = info[.editedImage] as? UIImage else {return}
        self.imageView.image = image
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

