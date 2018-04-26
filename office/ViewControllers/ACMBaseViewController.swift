//
//  ACMBaseViewController.swift
//  office
//
//  Created by Rauhul Varma on 2/11/18.
//  Copyright © 2018 acm. All rights reserved.
//

import UIKit

class ACMBaseViewController: UIViewController { }

// MARK: - UIViewController
extension ACMBaseViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerForKeyboardNotifications()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterForKeyboardNotifications()
    }
}

// MARK: - UITextFieldDelegate
extension ACMBaseViewController: UITextFieldDelegate {
    @objc dynamic func nextResponder(current: UIResponder) -> UIResponder? {
        return nil
    }

    @objc dynamic func actionForFinalResponder() { }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let nextReponder = nextResponder(current: textField) {
            nextReponder.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            actionForFinalResponder()
        }
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
        textField.layoutIfNeeded()
    }
}

// MARK: - Keyboard Notifications
extension ACMBaseViewController {
    @objc dynamic func keyboardWillShow(_ notification: NSNotification) { }

    @objc dynamic func keyboardWillHide(_ notification: NSNotification) { }

    func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
    }

    func unregisterForKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    func animateWithKeyboardLayout(notification: NSNotification, layout: ((CGRect) -> Void)?) {
        guard let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double,
            let curveValue = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? Int,
            let curve = UIViewAnimationCurve(rawValue: curveValue),
            let keyboardFrameValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardFrame = keyboardFrameValue.cgRectValue

        layout?(keyboardFrame)

        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(duration)
        UIView.setAnimationCurve(curve)
        view.layoutIfNeeded()
        UIView.commitAnimations()
    }
}
