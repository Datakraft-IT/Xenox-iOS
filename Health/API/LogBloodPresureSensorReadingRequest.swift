//
//  LogSensorReadingRequest.swift
//  Health
//
//  Created by Iaroslav Mamalat on 2017-09-20.
//  Copyright © 2017 Stefan Hellkvist. All rights reserved.
//

import APIKit

public struct LogBloodPressureSensorReadingRequest: XenoxRequest {
    public typealias Response = String
    
    public var method: HTTPMethod = .post
    
    public var path: String {
        return "/SensorReading/StoreBloodPressure"
    }
    
    private let systolic: Int
    private let distolic: Int
    private let createdDate: Date
    
    public var bodyParameters: BodyParameters? {
        return JSONBodyParameters(JSONObject: [
            "systolic": systolic,
            "distolic": distolic,
            "createdDate": createdDate.iso8601
        ])
    }
    
    public init(systolic: Int, distolic: Int, createdDate: Date) {
        self.systolic = systolic
        self.distolic = distolic
        self.createdDate = createdDate
    }
    
    public func response(from object: Any, urlResponse: HTTPURLResponse) throws -> String {
        return ""
    }
}
