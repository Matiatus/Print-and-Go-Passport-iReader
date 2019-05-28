//
//  ViewController.swift
//  iReader
//
//  Created by MAS on 3/21/19.
//  Copyright © 2019 PrintAndGo. All rights reserved.
//

import UIKit
import Alamofire

let baseURL = "https://printandgo.today"

class LoginController: UIViewController{

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    var csrf: String = ""
    let urlString = baseURL + "/login"
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        // Do any additional setup after loading the view, typically from a nib.
        usernameField.text = "readerauth"//"John_Doe_95"
        passwordField.isSecureTextEntry = true
        passwordField.text = "12345678" // "dummyPassword"
    
    }

    func hideKeyboardWhenTappedAround() {
        let tapGesture = UITapGestureRecognizer(target: self,
                                                action: #selector(hideKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func loginAttempt(_ sender: Any) {
        
        AF.request(self.urlString).response{response in
            switch response.result {
            case .success:
                if let data = response.data {
                    if let utf8Text = String(data: data, encoding: .utf8){
                        self.csrf = htmlGetValue(htmlString: utf8Text, key: "name=\"_csrf\" value=\"")
                        self.loginWithCSRF()
                    }
                }
            case .failure( _):
                createAlert(title: "Connection Failure", message: "Cannot connect to the server", sender: self)
            }
        }
    }
    
    func loginWithCSRF() {
        let parameters: [String: String] = [
            "username" : usernameField.text!,
            "password" : passwordField.text!,
            "_csrf": self.csrf
        ]
        AF.request(self.urlString, method: .post, parameters: parameters)
            .response { response in
                switch response.result {
                case .success:
                    if let responseURL = response.response?.url?.absoluteString {
                        if responseURL.contains("error"){
                            createAlert(title: "Login Failed", message: "Invalid username/password", sender: self)
                        } else {
                            self.performSegue(withIdentifier: "readPassport",sender: self)
                        }
                    }
                case .failure( _):
                    createAlert(title: "Connection Failure", message: "Cannot connect to the server", sender: self)
                }
        }
    }
    
}

func createAlert(title: String, message: String, sender: UIViewController) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
    
    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (action) in
        alert.dismiss(animated: true, completion: nil)
    }))
    
    sender.present(alert, animated: true, completion: nil)
}

func htmlGetValue(htmlString: String, key: String) -> String{
    if let range = htmlString.range(of: key) {
        var substring = htmlString[range.upperBound...]
        if let index = substring.firstIndex(of: "\""){
            substring = substring[..<index]
            return String(substring)
        } else {
            return ""
        }
    } else{
        return ""
    }
}

