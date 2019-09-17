//
//  XenoxRequest.swift
//  Health
//
//  Created by Iaroslav Mamalat on 2017-09-20.
//  Copyright © 2017 Stefan Hellkvist. All rights reserved.
//

import Foundation
import APIKit

enum XenoxRequestError: Error {
    case SomethingWentWrong
}

public protocol XenoxRequest: Request {}

public extension XenoxRequest {
    
    public var baseURL: URL {
//        return URL(string: "http://192.168.56.1:5000")!
        return URL(string: "https://dev.xenox-med.com")!
//        return URL(string: "https://xenox-med.com")!
//        return URL(string: "http://xenoxmednet20170922091925.azurewebsites.net")!
//        return URL(string: "https://alpha.xenox-med.com")!
    }
    
    internal var clientId: String {
        return ""
    }
    
    public func intercept(object: Any, urlResponse: HTTPURLResponse) throws -> Any {
        guard 200..<300 ~= urlResponse.statusCode else {
            print("err", object)
            throw XenoxRequestError.SomethingWentWrong
        }
        
        return object
    }
    
    public var headerFields: [String:String] {
        var headers: [String:String] = [:]
        
        if let id = UserDefaults.standard.value(forKey: "patient_id") as? String {
            headers["syncCode"] = id
        }
        
        return headers
    }
    
    
}
