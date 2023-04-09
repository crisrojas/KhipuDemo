//
//  Main.swift
//  Khipu
//
//  Created by Cristian Felipe Patiño Rojas on 07/04/2023.
//

import Foundation
import Models

protocol UseCase {
    associatedtype RequestType
    associatedtype ResponseType
    func request(_ request: RequestType)
}

public enum Message {
    case cmd(AppState.Change)
    case edit(Bool)
    
    var change: AppState.Change? {
        switch self {
        case .cmd(let change): return change
        default: return nil
        }
    }
}

public typealias Input  = (Message) -> ()
public typealias Output = (Message) -> ()
 
public func createCore(
    output: @escaping Output,
    recorder: TimelineRecorderMiddleware,
    store: DefaultStore
) -> Input  {
    
    // State UseCases
    let adder   = Adder  (store: store)
    let deleter = Deleter(store: store)
    let changer = Changer(store: store)
    
    // Middlewares
    let logger    = Logger()
    let reloader = HotReloader<AppState> {store.inject($0)}
    
    return {
        
        logger.request(.log(message: $0, state: store.state()))
        if case let .add(todo)    = $0.change {adder.request(.add(todo))}
        if case let .delete(todo) = $0.change {deleter.request(.delete(todo))}
        if case let .change(t, c) = $0.change {changer.request(.change(t, with: c))}
        if case let .edit(editing) = $0 {store.change(.editing(editing))}
        reloader.write(store.state())
        recorder.register(state: store.state())
    }
}

