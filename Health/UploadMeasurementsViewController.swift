//
//  UploadMeasurementsViewController.swift
//  Health
//
//  Created by Iaroslav Mamalat on 2017-09-18.
//  Copyright © 2017 Stefan Hellkvist. All rights reserved.
//

import UIKit
import Cartography
import APIKit
import HealthKit
import PromiseKit

class UploadMeasurementsViewController: UIViewController {
    
    var healthStore = HKHealthStore()
    
    lazy var uploadButton: UIButton = {
        let button = UIButton()
        button.setTitle("Upload measurements", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .blue
        button.layer.cornerRadius = 4
        button.layer.masksToBounds = true
        return button
    }()
    
    lazy var patientIDLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray
        label.textAlignment = .center
        return label
    }()
    
    lazy var logoutButton: UIButton = {
        let button = UIButton()
        button.setTitle("Logout", for: .normal)
        button.setTitleColor(.red, for: .normal)
        button.backgroundColor = .none
        return button
    }()
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: "patient_id")
        navigationController?.popViewController(animated: true)
    }
    
    func readAndUpload() {
        
        authorizeHealthKit() {
            success, err in
            
            guard success else { return }
            
            
            // HKQuantityTypeIdentifier
            let systolicPromise = self.readSample(type: HKSampleType.quantityType(forIdentifier: .bloodPressureSystolic)!)
            let distolicPromise = self.readSample(type: HKSampleType.quantityType(forIdentifier: .bloodPressureDiastolic)!)
            let heartRatePromise = self.readSample(type: HKSampleType.quantityType(forIdentifier: .heartRate)!)
            let glucosePromise = self.readSample(type: HKSampleType.quantityType(forIdentifier: .bloodGlucose)!)
            
            firstly {
                when(fulfilled: systolicPromise, distolicPromise, heartRatePromise, glucosePromise)
            }.then { systolic, distolic, heartRate, glucose -> Void in
                
                
                self.uploadDataHeartRate(heartRate: heartRate)
                self.uploadDataBloodPressure(systolic: systolic, distolic: distolic)
                self.uploadDataGlucose(glucose: glucose)
                
                self.dataUploaded()
            }.catch { error in
                print(error)
            }
        }

    }
    
    
    func readSample(type: HKSampleType) -> Promise<HKSample?> {
        return Promise { fulfill, reject in
            let past = Date.distantPast
            let now = Date()
            
            let limit = 1
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            
            let mostRecentPredicate = HKQuery.predicateForSamples(withStart: past, end: now, options: [])
            
            let sampleQuery = HKSampleQuery(sampleType: type, predicate: mostRecentPredicate, limit: limit, sortDescriptors: [sortDescriptor])
            { (sampleQuery, results, error ) -> Void in
                
                guard let sample = results?.first as? HKQuantitySample else {
                    
                    return fulfill(nil)
                }
                
                fulfill(sample)
            }
            // 5. Execute the Query
            self.healthStore.execute(sampleQuery)
        }

    }
    
    func uploadDataGlucose(glucose: HKSample?) {
        
        guard let glucoseQS = glucose as? HKQuantitySample
            else { return }
        
        let bloodGlucoseUnit = HKUnit(from: "mg/dL")
        let glucoseValue = Double(glucoseQS.quantity.doubleValue(for: bloodGlucoseUnit));
        
        let req = LogGlucoseSensorReadingRequest(glucoseLevel: glucoseValue, createdDate: glucoseQS.startDate)
        Session.send(req) {
            switch $0 {
            case .success(_):
                print("blood glucose")
            case .failure(let error):
                print("log sensor reading request", error)
            }
        }
        
    }
    
    func uploadDataHeartRate(heartRate: HKSample?) {
        
        guard let heartRateQS = heartRate as? HKQuantitySample
            else { return }
        
        let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
        
        let heartRateValue = Int(heartRateQS.quantity.doubleValue(for: heartRateUnit))
        
        let req = LogHeartRateSensorReadingRequest(heartRate: heartRateValue, createdDate: heartRateQS.startDate)
        
        Session.send(req) {
            switch $0 {
            case .success(_):
                print("heart rate")
            case .failure(let error):
                print("log sensor reading request", error)
            }
        }
        
    }
    
    func uploadDataBloodPressure(systolic: HKSample?, distolic: HKSample?) {
        
        guard let systolicQS = systolic as? HKQuantitySample,
        let distolicQS = distolic as? HKQuantitySample
        else { return }

        let bloodPressureUnit = HKUnit.millimeterOfMercury()
//        let heartRateUnit = heartRate?.quantity.doubleValue(for: HKUnit.minute())
        
        let systolicValue = Int(systolicQS.quantity.doubleValue(for: bloodPressureUnit))
        let distolicValue = Int(distolicQS.quantity.doubleValue(for: bloodPressureUnit))
        
        let req = LogBloodPressureSensorReadingRequest(systolic: systolicValue, distolic: distolicValue, createdDate: systolicQS.startDate)
        
        Session.send(req) {
            switch $0 {
                case .success(_):
                    print("blood pressure")
                case .failure(let error):
                    print("log sensor reading request", error)
            }
        }
        
    }
    
    func dataUploaded() {
        let alert = UIAlertController(title: "Congrads",
                                      message: "Your health data was successfully uploaded",
                                      preferredStyle: UIAlertControllerStyle.alert)
        
        let cancelAction = UIAlertAction(title: "OK",
                                         style: .cancel, handler: nil)
        
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
    func dataFailedToUpload () {
        let alert = UIAlertController(title: "Damn",
                                      message: "Something went wrong while uploading health data",
                                      preferredStyle: UIAlertControllerStyle.alert)
        
        let cancelAction = UIAlertAction(title: "OK",
                                         style: .cancel, handler: nil)
        
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
    let code: String

    init(code: String) {
        self.code = code
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        patientIDLabel.text = UserDefaults.standard.value(forKey: "patient_id") as? String
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        uploadButton.addTarget(self, action: #selector(readAndUpload), for: .touchUpInside)
        logoutButton.addTarget(self, action: #selector(logout), for: .touchUpInside)
        
        
        view.addSubview(logoutButton)
        view.addSubview(uploadButton)
        view.addSubview(patientIDLabel)
        
        layoutUI()
    }
    
    private func layoutUI() {
        constrain(uploadButton, logoutButton, patientIDLabel) {
            upload, logout, label in
            
            upload.height == 40
            upload.width == 200
            upload.center == upload.superview!.center
            
            logout.centerX == logout.superview!.centerX
            logout.bottom == logout.superview!.bottom - 20
            
            label.top == label.superview!.top + 40
            label.centerX == label.superview!.centerX
        }
    }
    
    func authorizeHealthKit(completion: @escaping (_ success: Bool, _ error: NSError?) -> Void) {
        


        // 1. Set the types you want to read from HK Store
        let healthKitTypesToRead : Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
            HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .bloodGlucose)!,
            HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!,
            HKObjectType.characteristicType(forIdentifier: .bloodType)!,
            HKObjectType.characteristicType(forIdentifier: .biologicalSex)!,
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,
        ]
        
        // 2. Set the types you want to write to HK Store
        let healthKitTypesToWrite : Set<HKSampleType> = []
        
        // 3. If the store is not available (for instance, iPad) return an error and don't go on.
        if !HKHealthStore.isHealthDataAvailable()
        {
            let error = NSError(domain: "org.hellkvist.Health", code: 2, userInfo: [NSLocalizedDescriptionKey:"HealthKit is not available in this Device"])
            
            completion(false, error)
            return;
        }
        
        // 4.  Request HealthKit authorization
        healthStore.requestAuthorization(toShare: healthKitTypesToWrite, read: healthKitTypesToRead) { (success, error) -> Void in
            
            completion(success, error as NSError?)
        }
    }

}
