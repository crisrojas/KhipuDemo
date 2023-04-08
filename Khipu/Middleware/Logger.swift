//
//  Logger.swift
//  Khipu
//
//  Created by Cristian Felipe Patiño Rojas on 08/04/2023.
//

import Foundation


public struct Logger: UseCase {
 
    enum Request { case log(message: Message, state: AppState) }
    enum Response {}
    
    typealias RequestType = Request
    typealias ResponseType = Response
    
    func request(_ request: Request) {
        if case .log(let message, let state) = request {
            print("➡️ \(message)\n✅ \(state)\n")
        }
    }
    
    public init() {}
}

