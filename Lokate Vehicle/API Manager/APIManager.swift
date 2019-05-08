//
//  APIManager.swift
//  SocialSweat
//
//  Created by dev292 on 17/07/18.
//  Copyright © 2018 Cubet. All rights reserved.
//

import Alamofire

struct Constants {
   
    static let borderColor = UIColor(red: 117/255, green: 104/255, blue: 182/255, alpha: 1)
    
    static let blackColor =  UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.4)
     static let baseUrl = "https://my-json-server.typicode.com/FlashScooters/Challenge"
}

class Connectivity {
    class func isConnectedToInternet() ->Bool {
        return NetworkReachabilityManager()!.isReachable
    }
}

public class APIUrls {
    ///set domain in plist while changing the environment
    static let development = "http://192.168.1.20:3000/"
    static let staging = ""
    static let production = ""
}


struct Endpoint {
    static let UploadImage = "upload"
    static let Train = "train"
}

enum APIManager {
    private static let baseURL = APIUrls.development
   
   case Upload()
   case Train(email: String, password: String)
   
    private var parameters: Parameters? {
        switch(self) {
            
        case.Upload:
            return nil
            
        case .Train(let imagename, let tagname):
             let parameters = ["imagename": imagename, "tagname": tagname]
             return parameters
        }
    }
    
    private var path: String {
        switch(self) {
        case .Upload:
            return Endpoint.UploadImage
            
        case .Train:
            return Endpoint.Train
        }
    }
    
    private var method: HTTPMethod {
        switch(self) {
        case .Upload,.Train:
            return .post
            
        }
    }
    
    private var headers: HTTPHeaders? {
        switch(self) {
        case .Upload,.Train :
            let headers : HTTPHeaders = [
                "Content-Type": "application/json"
            ]
            return headers
            
        }
    }
    
    
    ///method to handle api requests
    func requestURL(success:@escaping (Data) -> Void, failure:@escaping (Error) -> Void) {
        Alamofire.request(APIManager.baseURL + self.path, method: self.method, parameters: self.parameters, encoding: JSONEncoding.default, headers: self.headers).responseJSON { (response) in
            if response.result.isSuccess {
                #if DEBUG
                print("request url: \(String(describing: response.request?.url!))")
                print("\(self.path) response : " + "\(response.result.value as! NSDictionary)")
                #endif
                success(response.data!)
            }
            if response.result.isFailure {
                #if DEBUG
                print(response.result)
                #endif
                failure(response.result.error!)
            }
        }
    }
    
    /// method to handle file upload requests
    func requestWithFileUpload(file: Data?, fileName: String, success:@escaping (Data) -> Void, failure:@escaping (Error) -> Void){
        Alamofire.upload(multipartFormData: { (multipartFormData) in
            if file != nil {
                let image = UIImage(data: file!)
                
                multipartFormData.append(image!.jpegData(compressionQuality: 0.1)!, withName: fileName, fileName: "image.jpg", mimeType: "image/jpeg")
            }
            if(self.parameters != nil){
            for (key, value) in self.parameters! {
                let val = value as! String
                multipartFormData.append(val.data(using: .utf8)!, withName: key)
            }
            }
            
        }, usingThreshold: UInt64.init(), to: APIManager.baseURL + self.path, method: self.method, headers: self.headers) { (result) in
            switch result{
            case .success(let upload, _, _):
                upload.responseJSON { (response) in
                    if response.result.isSuccess {
                        #if DEBUG
                        print( "request url: \(String(describing: response.request?.url!))")
                        print("\(self.path) response : " + "\(response.result.value as! NSDictionary)")
                       
                        #endif
                        success(response.data!)
                    }
                    if response.result.isFailure {
                        #if DEBUG
                        print(self.debugResponseError(response: response.result))
                    
                        #endif
                        failure(response.result.error!)
                    }
                }
            case .failure(let error):
                failure(error)
            }
        }
    }

    
    
    func debugResponseError(response: Result<Any>) -> String {
        ///debug failure
        guard case let .failure(error) = response else { return "" }
        
        var errorReason = String()
        
        if let error = error as? AFError {
            switch error {
            case .invalidURL(let url):
                errorReason = "Invalid URL: \(url) - \(error.localizedDescription)"
            case .parameterEncodingFailed(let reason):
                errorReason = "Parameter encoding failed: \(error.localizedDescription)"
                errorReason = "Failure Reason: \(reason)"
            case .multipartEncodingFailed(let reason):
                errorReason = "Multipart encoding failed: \(error.localizedDescription)"
                errorReason = "Failure Reason: \(reason)"
            case .responseValidationFailed(let reason):
                errorReason = "Response validation failed: \(error.localizedDescription)"
                errorReason = "Failure Reason: \(reason)"
                
                switch reason {
                case .dataFileNil, .dataFileReadFailed:
                    errorReason = "Downloaded file could not be read"
                case .missingContentType(let acceptableContentTypes):
                    errorReason = "Content Type Missing: \(acceptableContentTypes)"
                case .unacceptableContentType(let acceptableContentTypes, let responseContentType):
                    errorReason = "Response content type: \(responseContentType) was unacceptable: \(acceptableContentTypes)"
                case .unacceptableStatusCode(let code):
                    errorReason = "Response status code was unacceptable: \(code)"
                }
            case .responseSerializationFailed(let reason):
                errorReason = "Response serialization failed: \(error.localizedDescription)"
                errorReason = "Failure Reason: \(reason)"
            }
            
            errorReason = "Underlying error: \(String(describing: error.underlyingError))"
        } else if let error = error as? URLError {
            errorReason = "URLError occurred: \(error)"
        } else {
            errorReason = "Unknown error: \(error)"
        }
        
        return errorReason
    }
}
