//
//  IdentificationViewController.swift
//  Health
//
//  Created by Iaroslav Mamalat on 2017-09-18.
//  Copyright © 2017 Stefan Hellkvist. All rights reserved.
//

import UIKit
import Cartography

class IdentificationViewController: UIViewController {

    lazy var identificationTextInput: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Identification Code"
        textField.textAlignment = .center
        textField.autocapitalizationType = .none
        return textField
    }()
    
    lazy var submitButton: UIButton = {
        let button = UIButton()
        button.setTitle("Submit", for: .normal)
        button.setTitleColor(.blue, for: .normal)
        return button
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        identificationTextInput.text = UserDefaults.standard.value(forKey: "patient_id") as? String
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tap)
        
        submitButton.addTarget(self, action: #selector(sendIdentificationRequest), for: .touchUpInside)
        
        identificationTextInput.delegate = self
        
        view.addSubview(identificationTextInput)
        view.addSubview(submitButton)
        
        layoutUI()
    }
    
    func sendIdentificationRequest() {
        
        guard let idCode = identificationTextInput.text, idCode != "" else {
            let alert = UIAlertController(title: "Wrong Patient ID",
                                          message: "This Patient ID is not available or never existed",
                                          preferredStyle: UIAlertControllerStyle.alert)
            
            let cancelAction = UIAlertAction(title: "OK",
                                             style: .cancel, handler: nil)
            
            alert.addAction(cancelAction)
            identificationTextInput.text = nil
            return self.present(alert, animated: true)
        }
        
        UserDefaults.standard.set(idCode, forKey: "patient_id")
        
        goToUploadWithPatientID(idCode)
    }
    
    func goToUploadWithPatientID(_ idCode: String) {
        let viewController = UploadMeasurementsViewController(code: idCode)
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func layoutUI() {
        constrain(identificationTextInput, submitButton) {
            textInput, submit in
            
            textInput.center == textInput.superview!.center
            submit.top == textInput.bottom + 20
            submit.centerX == submit.superview!.centerX
        }
    }

}

extension IdentificationViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    func hideKeyboard() {
        identificationTextInput.resignFirstResponder()
    }

    
}
