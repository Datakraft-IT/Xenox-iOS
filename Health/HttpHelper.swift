//
//  HttpHelper.swift
//  Our15s
//
//  Created by Stefan Hellkvist on 23/03/16.
//  Copyright © 2016 Stefan Hellkvist. All rights reserved.
//

import Foundation
import UIKit

class HttpHelperDelegate: NSObject, URLSessionDelegate, URLSessionDataDelegate {
    func urlSession(_ session: URLSession,
                    didBecomeInvalidWithError error: Error?){
        NSLog("HTTP session \(session) did become invalide: \(error)")
    }
    
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        NSLog("HTTP session \(session) did receive challenge: \(challenge)")
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        NSLog("HTTP session \(session) did finish events")
    }
    
    
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void){
        NSLog("HTTP session \(session) did receive response \(response)")
    }
    
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didBecome downloadTask: URLSessionDownloadTask){
        NSLog("HTTP session \(session) did become downloadTask \(downloadTask)")
    }
    
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didBecome streamTask: URLSessionStreamTask){
        NSLog("HTTP session \(session) did become streamTask \(streamTask)")
    }
    
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive data: Data){
        NSLog("HTTP session \(session) did receive data \(data)")
    }
    
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    willCacheResponse proposedResponse: CachedURLResponse,
                    completionHandler: @escaping (CachedURLResponse?) -> Void){
        NSLog("HTTP session \(session) will cache response \(proposedResponse)")
    }
}

class HttpHelper {
    static var delegate : HttpHelperDelegate = HttpHelperDelegate()
    
    static func getJSON(url: String, callback: @escaping (AnyObject) -> Void) {
        getJSON(url: url, headers: [], callback: callback)
    }
    
    
    static func getJSON(url: String, headers: [(key: String, value: String)], callback: @escaping (AnyObject) -> Void) {
        
        httpRequest(url: url, method: "GET", headers: headers, data: nil) {
            (data: NSData?) in
            
            do {
                if let data = data {
                    let result = try JSONSerialization.jsonObject(with: data as Data, options: [])
                    callback(result as AnyObject)
                } else {
                    print("Failed to fetch and/or parse data from \(url)")
                    callback(NSArray())
                }
            }
            catch {
                print("Failed to fetch and/or parse data from \(url)")
                callback(NSArray())
            }
        }
    }
    
    
    static func postJSON(url: String, doc: Dictionary<String, Any>, callback: @escaping (Bool, _ response: AnyObject?) -> Void) -> Void {
        
        var headers:[(key: String, value: String)] = []
        headers.append((key: "Content-Type", value: "application/json"))
        headers.append((key: "Accept", value: "application/json"))
        
        do {
            let data = try JSONSerialization.data(withJSONObject: doc, options: JSONSerialization.WritingOptions.prettyPrinted)
            
            httpRequest(url: url, method: "POST", headers: headers, data: data as NSData?) {
                (data: NSData?) in
                
                if let response = data {
                    do {
                        let result = try JSONSerialization.jsonObject(with: response as Data, options: [])
                        callback(true, result as AnyObject?)
                    } catch  {
                        callback(true, nil)
                    }
                } else {
                    print("did not get any data back from json post")
                    callback(false, nil)
                }
            }
        }
            
        catch {
            print("error when posting JSON")
        }
    }
    
    static func httpRequest(url: String, method: String, headers: [(key: String, value: String)], data: NSData?, callback: @escaping (NSData?) -> Void) -> Void {
        
        NSLog("HTTP request: \(method) \(url)")
        
        let request = NSMutableURLRequest(url: NSURL(string: url)! as URL)
        request.httpMethod = method
        
        if let body = data {
            request.httpBody = body as Data
        }
        
        for h in headers {
            let (key, value) = h
            request.setValue(value, forHTTPHeaderField: key)
        }
        
                
        // create the session
        let config = URLSessionConfiguration.default
        
        if method == "GET" {
            config.requestCachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        }
        
        let session = URLSession(configuration: config)
        /*let session = URLSession(configuration: config, delegate: HttpHelper.delegate, delegateQueue: OperationQueue.main)*/
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            data, response, error -> Void in
            
            guard let _:NSData = data as NSData?, let _:URLResponse = response  , error == nil else {
                NSLog("error when uploading data")
                callback(nil)
                return
            }
            
            let httpResponse = response as! HTTPURLResponse
            NSLog("status code was \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                callback(nil)
            } else {
                callback(data! as NSData?)
            }
        })
        task.resume()
    }
    
    static func postData(url: String, headers: [(key: String, value: String)], data: Data, callback: @escaping (NSData?) -> Void) -> Void {
        
        httpRequest(url: url, method: "POST", headers: headers, data: data as NSData?, callback: callback)
    }
    
    static func getData(url: String, callback: @escaping (NSData?) -> Void) {
        httpRequest(url: url, method: "GET", headers: [], data: nil, callback: callback)
    }
}
