//
//  LoginViewController.swift
//  audioRec
//
//  Created by Michael Roundcount on 7/19/18.
//  Copyright © 2018 Michael Roundcount. All rights reserved.
//


//Michael Code
import UIKit

class LoginViewController: UIViewController {

    @IBOutlet var _username: UITextField!
    @IBOutlet var _password: UITextField!
    @IBOutlet var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let preferences = UserDefaults.standard
        
        if(preferences.object(forKey: "session") != nil) {
            LoginDone()
        } else {
            LoginToDo()
        }
        
    }
    //adding a _to the text fields so that they do not reference the vaiables
    @IBAction func loginButton(_ sender: Any) {
        
        if(loginButton.titleLabel?.text == "Logout") {
            let preferences = UserDefaults.standard
            preferences.removeObject(forKey: "session")
            
            LoginToDo()
            return
        }
        
        let username = _username.text
        let password = _password.text
        
        if (username == "" || password == "") {
            return
        }
        
        DoLogin(username!, password!)
    }
    
    func DoLogin(_ user:String, _ psw:String){
        
        //test API link
        let url = URL(string: "http://www.kaleidosblog.com/tutorial/login/api/login")
        let session = URLSession.shared
        
        let request = NSMutableURLRequest(url: url!)
        request.httpMethod = "POST"
        
        let paramToSend = "username" + user + "&password" + psw
        
        request.httpBody = paramToSend.data(using: String.Encoding.utf8)
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
        (data, response, error) in
            
            guard let _:Data = data else {
                return
            }
            let json:Any?
            
            do {
                json = try JSONSerialization.jsonObject(with: data!, options: [])
            }
            catch {
                return
            }
            guard let server_response = json as? NSDictionary else {
                return
            }
            
            if let data_block = server_response["data"] as? NSDictionary {
                if let session_data = data_block["session"] as? String {
                    let preferences = UserDefaults.standard
                    preferences.set(session_data, forKey: "session")
                    
                    DispatchQueue.main.async (
                        execute:self.LoginDone
                            )
                }
            }
        })
        task.resume()
    }
    
    func LoginToDo() {
        _username.isEnabled = true
        _password.isEnabled = true
        
        loginButton.setTitle("Login", for: .normal)
    }
    
    func LoginDone() {
        _username.isEnabled = false
        _password.isEnabled = false
        
        loginButton.setTitle("Logout", for: .normal)
    }
}
