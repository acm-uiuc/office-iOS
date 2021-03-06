//
//  LoginViewController.swift
//  office
//
//  Created by Rauhul Varma on 2/11/18.
//  Copyright © 2018 acm. All rights reserved.
//

import UIKit
import SwiftKeychainAccess

class ACMLoginViewController: ACMBaseViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var netIDField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var bottomLayoutConstraint: NSLayoutConstraint!
    
    

    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        loginButton.layer.cornerRadius = 4
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        netIDField.textContentType = .username
        passwordField.textContentType = .password
        
        netIDField.text = nil
        passwordField.text = nil

        loginButton.isEnabled = true
    }

    // MARK: - Next Responder
    override func nextResponder(current: UIResponder) -> UIResponder? {
        switch current {
        case netIDField:
            return passwordField
        case passwordField:
            return nil
        default:
            return nil
        }
    }

    // MARK: - Keyboard
    override func keyboardWillShow(_ notification: NSNotification) {
        super.keyboardWillShow(notification)

        animateWithKeyboardLayout(notification: notification) { (keyboardRect) in
            self.bottomLayoutConstraint.constant = keyboardRect.height
        }
    }

    override func keyboardWillHide(_ notification: NSNotification) {
        super.keyboardWillHide(notification)

        animateWithKeyboardLayout(notification: notification) { (keyboardRect) in
            self.bottomLayoutConstraint.constant = 0
        }
    }

    // MARK: - Editing
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }

    // MARK: - IBActions
    @IBAction func login(sender: Any?) {
        let netID = netIDField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard netID != "" && password != "" else {
            let alertViewController = UIAlertController(title: "Incomplete", message: nil, preferredStyle: .alert)
            alertViewController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertViewController, animated: true, completion: nil)
            return
        }

        view.endEditing(true)

        loginButton.isEnabled = false
        loginButton.alpha     = 0.5

        ConcertService.createSessionFor(user: netID, withPassword: password)
        .onCompletion { result in
            switch result {
            case .success(_, let cookies):
                let connectionURL = URL(string: "https://concert.acm.illinois.edu")!
                let headers = HTTPCookie.cookies(
                    withResponseHeaderFields: cookies as! [String : String],
                    for: connectionURL
                )
                
                ACMApplicationController.shared.extractedCookies = headers
                let passwordAlert = UIAlertController(title: "Save Password?", message: "asdfasdfasdfasdfasdf", preferredStyle: UIAlertControllerStyle.alert)
                let yesOption = UIAlertAction(title: "Yes", style: .default) { _ in
                    ACMApplicationController.shared.keychain.store(password, forKey: netID)
                    self.performSegue(withIdentifier: "showConcertPlayer", sender: nil)
                }
                let noOption = UIAlertAction(title: "No", style: .default){ _ in
                    self.performSegue(withIdentifier: "showConcertPlayer", sender: nil)
                }
                passwordAlert.addAction(noOption)
                passwordAlert.addAction(yesOption)
                
                DispatchQueue.main.async {
//                    self.present(passwordAlert, animated: true, completion: nil)
                    self.performSegue(withIdentifier: "showConcertPlayer", sender: nil)
                    
                }
            case .cancellation: break
            case .failure(let error):
                let alertViewController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                alertViewController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                DispatchQueue.main.async {
                    self.present(alertViewController, animated: true, completion: nil)
                }
            }
            DispatchQueue.main.async {
                self.loginButton.isEnabled = true
                self.loginButton.alpha     = 1.0
            }
        }
        .launch()
    }
}
