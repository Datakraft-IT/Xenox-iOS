//
//  LogGlucoseSensorReadingRequest.swift
//  Health
//
//  Created by Iaroslav Mamalat on 2018-05-29.
//  Copyright © 2018 Stefan Hellkvist. All rights reserved.
//

import APIKit

public struct LogGlucoseSensorReadingRequest: XenoxRequest {
    public typealias Response = String
    
    public var method: HTTPMethod = .post
    
    public var path: String {
        return "/SensorReading/StoreBloodGlucose"
    }
    
    private let glucoseLevel: Double
    private let createdDate: Date
    
    public var bodyParameters: BodyParameters? {
        return JSONBodyParameters(JSONObject: [
            "glucoseLevel": glucoseLevel,
            "createdDate": createdDate.iso8601
        ])
    }
    
    public init(glucoseLevel: Double, createdDate: Date) {
        self.glucoseLevel = glucoseLevel
        self.createdDate = createdDate
    }
    
    public func response(from object: Any, urlResponse: HTTPURLResponse) throws -> String {
        return ""
    }
}
