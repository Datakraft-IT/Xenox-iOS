//
//  LogHeartRateSensorReadingRequest.swift
//  Health
//
//  Created by Iaroslav Mamalat on 2017-11-29.
//  Copyright © 2017 Stefan Hellkvist. All rights reserved.
//

import APIKit

public struct LogHeartRateSensorReadingRequest: XenoxRequest {
    public typealias Response = String
    
    public var method: HTTPMethod = .post
    
    public var path: String {
        return "/SensorReading/StoreHeartRate"
    }
    
    private let heartRate: Int
    private let createdDate: Date
    
    public var bodyParameters: BodyParameters? {
        return JSONBodyParameters(JSONObject: [
            "heartRate": heartRate,
            "createdDate": createdDate.iso8601
        ])
    }
    
    public init(heartRate: Int, createdDate: Date) {
        self.heartRate = heartRate
        self.createdDate = createdDate
    }
    
    public func response(from object: Any, urlResponse: HTTPURLResponse) throws -> String {
        return ""
    }
}
