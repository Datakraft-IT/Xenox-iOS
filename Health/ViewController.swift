//
//  ViewController.swift
//  Health
//
//  Created by Stefan Hellkvist on 28/10/16.
//  Copyright © 2016 Stefan Hellkvist. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {
    var healthStore: HKHealthStore!
    
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var infoTextView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
       
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.black.cgColor
        healthStore = HKHealthStore()
    }

    func getApiEndpoint() -> String {
        let defaults = UserDefaults.standard
        return defaults.string(forKey: "endpoint_preference")!
    }
    
    func getUserId() -> Int {
        let defaults = UserDefaults.standard
        return defaults.integer(forKey: "user_id_preference")
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


    @IBAction func buttonPressed(_ sender: AnyObject) {
        
        
        if HKHealthStore.isHealthDataAvailable() {
            self.infoTextView.text = "found all required data"
            
            authorizeHealthKit() {
                (success : Bool, error: NSError?) in
                
                /*
                DispatchQueue.main.async {
                    self.infoTextView.text = self.infoTextView.text + "\nauthorized: \(success)"
                    do {
                        try self.infoTextView.text = self.infoTextView.text + "\nblood type: \(self.healthStore.bloodType().bloodType.rawValue)"
                        
                        try self.infoTextView.text = self.infoTextView.text + "\ndate of birth: \(self.healthStore.dateOfBirthComponents().description)"
                        
                        try self.infoTextView.text = self.infoTextView.text + "\nbiological sex: \(self.healthStore.biologicalSex().description)"
                    }
                    catch {
                        print("problem when reading data")
                    }
                }
                
                self.readMostRecentSample(sampleType: HKSampleType.quantityType(forIdentifier: .bodyTemperature)!) {
                    (sample: HKSample?, error: NSError?) in
                    
                    if let s = sample {
                        DispatchQueue.main.async {
                            
                            self.infoTextView.text = self.infoTextView.text + "\nbody temperature: \(s)"
                        }
                    } else {
                        print("no data found for: \(HKSampleType.quantityType(forIdentifier: .bodyTemperature)!)")
                    }
                }
                */
                
                var samples : [HKSample] = []
                
                self.readMostRecentSample(sampleType: HKSampleType.quantityType(forIdentifier: .bloodPressureSystolic)!) {
                    (sample: HKSample?, error: NSError?) in
                    
                    if let s = sample {
                        
                        samples.append(s)
                        
                        self.readMostRecentSample(sampleType: HKSampleType.quantityType(forIdentifier: .bloodPressureDiastolic)!) {
                            (sample: HKSample?, error: NSError?) in
                            
                            if let s = sample {
                                
                                samples.append(s)
                                
                                self.uploadSamples(samples: samples)
                            } else {
                                DispatchQueue.main.async {
                                    self.infoTextView.text = self.infoTextView.text + "\nno data found for: \(HKSampleType.quantityType(forIdentifier: .bloodPressureDiastolic)!)"
                                }
                            }
                        }
                        
                        
                    } else {
                        DispatchQueue.main.async {
                            self.infoTextView.text = self.infoTextView.text + "\nno data found for: \(HKSampleType.quantityType(forIdentifier: .bloodPressureSystolic)!)"
                        }
                    }
                }
            }
        }
    }
    
    
    func uploadSamples(samples: [HKSample]) {
        let dict = ["timestamp": Date().iso8601,
                    "pt_id": getUserId(),
                    "samples": samplesToDicts(samples: samples)] as Dictionary<String, Any>
        
        DispatchQueue.main.async {
            self.infoTextView.text = self.infoTextView.text + "\nstarting upload..."
        }
        
        HttpHelper.postJSON(url: getApiEndpoint() + "samples/", doc: dict) {
            (uploaded: Bool, data : AnyObject?) in
            
            let msg = uploaded ? "all data uploaded" : "upload failed"
            
            DispatchQueue.main.async {
                self.infoTextView.text = self.infoTextView.text + "\n" + msg
            }
        }
    }
    
    func samplesToDicts(samples: [HKSample]) -> [Dictionary<String, Any>] {
        var arr: [Dictionary<String, Any>] = []
        
        for s in samples {
            if let qs = s as? HKQuantitySample {
                
                let dict = ["type" : qs.sampleType.description,
                            "value" : qs.quantity.doubleValue(for: HKUnit.millimeterOfMercury()),
                            "unit" : "mmHg",
                            "start": qs.startDate.iso8601,
                            "end": qs.endDate.iso8601]
                    as Dictionary<String, Any>
                
                arr.append(dict)
            }
        }
        
        return arr
    }
    
    func authorizeHealthKit(completion: @escaping (_ success: Bool, _ error: NSError?) -> Void) {
        
        
        // 1. Set the types you want to read from HK Store
        let healthKitTypesToRead : Set<HKObjectType> = [
            HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!,
            HKObjectType.characteristicType(forIdentifier: .bloodType)!,
            HKObjectType.characteristicType(forIdentifier: .biologicalSex)!,
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
            HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!,
            HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!
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
    
    func readMostRecentSample(sampleType:HKSampleType , completion: @escaping (HKSample?, NSError?) -> Void) {
        
        // 1. Build the Predicate
        let past = NSDate.distantPast as NSDate
        let now   = NSDate()
        let mostRecentPredicate = HKQuery.predicateForSamples(withStart: past as Date, end:now as Date, options: [])
        
        // 2. Build the sort descriptor to return the samples in descending order
        let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
        // 3. we want to limit the number of samples returned by the query to just 1 (the most recent)
        let limit = 1
        
        // 4. Build samples query
        let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: mostRecentPredicate, limit: limit, sortDescriptors: [sortDescriptor])
        { (sampleQuery, results, error ) -> Void in
            
            if error != nil {
                completion(nil,error as NSError?)
                return;
            }
            
            // Get the first sample
            let mostRecentSample = results?.first as? HKQuantitySample
            
            // Execute the completion closure
            
            completion(mostRecentSample,nil)
        }
        // 5. Execute the Query
        self.healthStore.execute(sampleQuery)
    }
}

extension Formatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()
}
extension Date {
    var iso8601: String {
        return Formatter.iso8601.string(from: self)
    }
}

extension String {
    var dateFromISO8601: Date? {
        return Formatter.iso8601.date(from: self)
    }
}
