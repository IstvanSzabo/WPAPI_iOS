//
//  WPAPIClient.swift
//  WPAPI
//
//  Created by SongXujie on 26/12/17.
//  Copyright © 2017 SK8 PTY LTD. All rights reserved.
//

import Foundation

public class WPClient {

    private let baseURL: String!
    private let session = URLSession(configuration: .default)
    
    private var authorizationToken: String?
    
    public static var sharedInstance: WPClient!
    
    public init(baseURL: String, authToken: String? = nil) {
        
        self.baseURL = baseURL
        self.authorizationToken = authToken
        WPClient.sharedInstance = self
    }
    
    /// Sends a request to WordPress servers, calling the completion method when finished
    public func send<T: WPRequest>(_ request: T, completion: @escaping ResultCallback<T.Response>) {
        
        // Determine end point
        let req = self.request(for: request)
        let task = session.dataTask(with: req) { data, response, error in
            if let data = data {
                do {
//                    print("Response data \(data.base64EncodedString())")
                    // Decode the top level response failed, decode as failure
                    // if it's a failure
                    let errorResponse = try JSONDecoder().decode(WPErrorResponse.self, from: data)
                    if let message = errorResponse.message {
                        completion(.failure(WPError.server(message: message)))
                    } else {
                        completion(.failure(WPError.decoding))
                    }
                } catch {
                    // Decode the top level response, and look up the decoded response to see
                    // if it's a success or a failure
                    do {
                        let apiResponse = try JSONDecoder().decode(T.Response.self, from: data)
                        completion(.success(apiResponse))
                    } catch {
                        completion(.failure(error))
                    }
                }
            } else if let error = error {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    /// Encodes a URL based on the given request
    /// Everything needed for a public request to WordPress servers is encoded directly in this URL
    private func request<T: WPRequest>(for request: T) -> URLRequest {
    
    // This timestamp and hash are needed for WordPress requests
//    let timestamp = Date().timeIntervalSince1970
//    let hash = "\(timestamp)\(privateKey)\(publicKey)".md5
    
    // Construct the final URL with all the previous data
//        return URL(string: "\(baseEndpoint)\(request.resourceName)?ts=\(timestamp)&hash=\(hash)&apikey=\(publicKey)&\(parameters)")!
        
        // Determine end point
        var endpoint: URL?
        switch request.method {
        case .get:
            guard let parameters = try? URLQueryEncoder.encode(request) else { fatalError("Wrong parameters") }
            endpoint = URL(string: "\(baseURL!)/wp-json\(request.pathName)?\(parameters)")
        default:
            endpoint = URL(string: "\(baseURL!)/wp-json\(request.pathName)")
        }
        
        print(request.method.rawValue + ": " + endpoint!.absoluteString)
        
        // Create Request
        var req = URLRequest(url: endpoint!)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let authToken = self.authorizationToken {
            req.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        req.httpMethod = request.method.rawValue
        if let body = request.body {
            req.httpBody = body
        }
        
        return req
    }
    
    public func updateAuthToken(authToken : String) {
        self.authorizationToken = authToken;
    }
    
    func logIn(username: String, password: String) {
        
    }
    
    func logOut() {
        
    }
}