//
//  Main.swift
//  Khipu
//
//  Created by Cristian Felipe Patiño Rojas on 07/04/2023.
//

import Foundation
import Models

public struct AppState {
    let todos: [ToDo]
}

public final class ViewState: ObservableObject {
    @Published public var todos = [ToDo]()
    
    public init(store: DefaultStore) {
        
        process(store.state())
        
        store.onChange { [weak self] in
            self?.process(store.state())
        }
    }
    
    private func process(_ state: AppState) {
        todos = state.todos
    }
}

public extension AppState {
    init() {todos = []}
    
    enum Change {
        case add(ToDo)
        case delete(ToDo)
        case change(ToDo, with: ToDo.Change)
    }
    
    func apply(_ change: Change) -> Self {
        switch change {
        case .add(let todo): return .init(todos: todos + [todo])
        case .delete(let todo): return .init(todos: todos.filter { $0.id != todo.id })
        case .change(let todo, let change):
            let todos = todos
                .filter { $0.id != todo.id }
                + [todo.apply(change)]
            return .init(todos: todos)
        }
    }
}

extension AppState: Codable {}
extension AppState.Change: Codable {}

public typealias Access<S> = (               ) -> S
public typealias Change<C> = (C              ) -> ()
public typealias Observe   = (@escaping()->()) -> ()
public typealias Inject<S> = (S              ) -> ()
public typealias DefaultStore = StateStore<AppState, AppState.Change>

public typealias StateStore<S,C> = (
    state: Access<S>,
    change: Change<C>,
    onChange: Observe,
    inject: Inject<S>
)

public enum Message {
    case cmd(AppState.Change)
    case replay
    
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
    let adder   = Adder  (store: store, responder: { _ in})
    let deleter = Deleter(store: store)
    let changer = Changer(store: store)
    
    // Middleware observers
    let logger    = Logger()
    let hotReload = HotReloader(store: store)
    
    return {
        recorder.register(state: store.state())
        logger.request(.log(message: $0, state: store.state()))
        if case let .add(todo)    = $0.change {adder.request(.add(todo))}
        if case let .delete(todo) = $0.change {deleter.request(.delete(todo))}
        if case let .change(t, c) = $0.change {changer.request(.change(t, with: c))}
        hotReload.write(store.state())
        if case .replay = $0 {recorder.replayTimeline {}}
    }
}

protocol UseCase {
    associatedtype RequestType
    associatedtype ResponseType
    func request(_ request: RequestType)
}


public func createRamStore() -> DefaultStore {
    var s = AppState(){didSet{c.forEach{$0()}}}
    var c = [()->()]()
    return (
        state: { s },
        change: { s = s.apply($0) },
        onChange: { c = c + [$0] },
        inject: { s = $0 }
    )
}


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

final class HotReloader {
    private var fileHandle: FileHandle?
    private var source: DispatchSourceFileSystemObject?
    private var url: URL!

    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()
    
    private let store: DefaultStore

    init(store: DefaultStore) {
        
        self.store = store
        setupPath()
        jsonEncoder.outputFormatting = .prettyPrinted
        try? Data().write(to: url)
        fileHandle = try! FileHandle(forReadingFrom: url)

        observeFile()
    }

    deinit {
        source?.cancel()
        try? fileHandle?.close()
    }

    func write(_ state: AppState) {
        guard let json = try? jsonEncoder.encode(state) else { return }

        source?.cancel()
        try? json.write(to: url)
        observeFile()
    }

    private func observeFile() {
        guard let fileHandle = fileHandle else { return assertionFailure() }

        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileHandle.fileDescriptor,
            eventMask: .extend,
            queue: .main
        )

        source?.setEventHandler { [weak self] in
            guard let self = self else { return }
            guard let data = try? Data(contentsOf: self.url) else { return assertionFailure() }
            guard let state = try? self.jsonDecoder.decode(AppState.self, from: data) else { return print("🔥 Failed to decode Hot Reload\n") }

            self.store.inject(state)
            print("🔥 Hot Reloaded state\n")
        }

        source?.resume()
    }

    private func setupPath() {
#if targetEnvironment(simulator)
        let regex = try! NSRegularExpression(pattern: "\\/Users\\/([^\\/]+)\\/", options: .caseInsensitive)
        let documentsPath = (try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)).absoluteString
        guard let match = regex.firstMatch(in: documentsPath, options: [], range: NSRange(location: 0, length: documentsPath.count)), match.numberOfRanges >= 1 else {
            fatalError("If it doesn't work remove this code and fill below your Macbook's username manually.")
        }

        let username = String(documentsPath[Range(match.range(at: 1), in: documentsPath)!])
        url = URL(fileURLWithPath: "/Users/\(username)/Desktop/hot_reload.json")
#else
        url = (try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false))
            .appendingPathComponent("hot_reload.json")
#endif

        print("🔥 Hot Reload path: \(url.absoluteString)\n")
    }
}


public final class TimelineRecorderMiddleware {
    public var totalSteps: Int { timeline.count }
    public var totalLength: TimeInterval { timeline.map(\.timeOffset).reduce(0.0, +) }

    private var timeline: [(timeOffset: TimeInterval, state: AppState)] = []
    private var shouldRecord = true
    private var lastStateChangeDate = Date()
    private let store: DefaultStore

    public init(store: DefaultStore) {
        self.store = store
        timeline = [(0.0, AppState())]
    }
    
    func register(state: AppState) {
        if shouldRecord {
            timeline.append((timeline.isEmpty ? 0.0 : Date().timeIntervalSince(lastStateChangeDate), state))
        }

        lastStateChangeDate = Date()
    }
    

    public func replayTimeline(completion: @escaping () -> ()) {
        shouldRecord = false
//        store.isEnabled = false
        replayNextStep(completion: completion)
    }

    private func replayNextStep(completion: @escaping () -> ()) {
        guard let step = timeline.first else {
//            store.isEnabled = true
            shouldRecord = true
            return completion()
        }

        timeline.remove(at: 0)

        DispatchQueue.main.asyncAfter(deadline: .now() + step.timeOffset) { [weak self] in
            self?.store.inject(step.state)
            self?.replayNextStep(completion: completion)
        }
    }
}
