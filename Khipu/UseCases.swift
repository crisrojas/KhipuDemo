//
//  UseCases.swift
//  Khipu
//
//  Created by Cristian Felipe Patiño Rojas on 08/04/2023.
//

import Foundation
import Models


struct Adder: UseCase {
    enum Request { case add(ToDo) }
    enum Response { case didAdd }
    
    typealias RequestType = Request
    typealias ResponseType = Response
    
    private let store: DefaultStore
    private let respond: (Response) -> ()
    
    func request(_ request: Request) {
        if case .add(let todo) = request {
            store.change(.add(todo))
            respond(.didAdd)
        }
    }
    
    init(store: DefaultStore, responder: @escaping (Response) -> ()) {
        self.store = store
        self.respond = responder
    }
}

struct Deleter: UseCase {
    enum Request { case delete(ToDo) }
    enum Response { case didAdd }
    
    typealias RequestType = Request
    typealias ResponseType = Response
    private let store: DefaultStore
    
    func request(_ request: Request) {
        if case .delete(let todo) = request {
            store.change(.delete(todo))
        }
    }
    
    init(store: DefaultStore) {
        self.store = store
    }
}

struct Changer: UseCase {
    enum Request { case change(ToDo, with: ToDo.Change) }
    enum Response { case didAdd }
    
    typealias RequestType = Request
    typealias ResponseType = Response
    private let store: DefaultStore
    
    func request(_ request: Request) {
        if case .change(let todo, let change) = request {
            store.change(.change(todo, with: change))
        }
    }
    
    init(store: DefaultStore) {
        self.store = store
    }
}
