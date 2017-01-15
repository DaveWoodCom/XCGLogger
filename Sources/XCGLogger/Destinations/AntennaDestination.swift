//
//  AntennaDestination.swift
//  GotYourBackServer
//
//  Created by Charlie Woloszynski on 1/15/17.
//
//

import Dispatch
import Foundation
import libc


open class AntennaDestination: BaseDestination {
    open var logQueue: DispatchQueue? = nil
    
    let formatter: DateFormatter
    var target: URL
    
    
    public init(target: URL) {
        self.target = target
        
        formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        formatter.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'"
    }
    
    open override func output(logDetails: LogDetails, message: String) {
        
        let outputClosure = {
            var logDetails = logDetails
            var message = message
            
            // Apply filters, if any indicate we should drop the message, we abort before doing the actual logging
            if self.shouldExclude(logDetails: &logDetails, message: &message) {
                return
            }
            
            let parameters = self.logDetailParameters(logDetails)
            
            //create the session object
            let session = URLSession.shared
            
            //now create the URLRequest object using the url object
            var request = URLRequest(url: self.target)
            request.httpMethod = "POST" //set http method as POST
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body
                
            } catch let error {
                print(error.localizedDescription)
            }
            
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            //create dataTask using the session object to send data to the server
            let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
                
                guard error == nil else {
                    return
                }
                
                guard let data = data else {
                    return
                }
                
                do {
                    //create json object from data
                    if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                        print(json)
                    }
                    
                } catch let error {
                    print(error.localizedDescription)
                }
            })
            task.resume()
            
        }
        
        if let logQueue = logQueue {
            logQueue.async(execute: outputClosure)
        }
        else {
            outputClosure()
        }
    }
    
    func logDetailParameters(_ logDetails: LogDetails) -> Dictionary<String, String> {
        let retvalue : [String: String] =
            ["level": logDetails.level.rawValue.description,
             "date" : formatter.string(from: logDetails.date),
             "message" : logDetails.message,
             "functionName" : logDetails.functionName,
             "fileName" : logDetails.fileName,
             "lineNumber" : logDetails.lineNumber.description
        ]
        return retvalue
    }

}
