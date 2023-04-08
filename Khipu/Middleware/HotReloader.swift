//
//  HotReloader.swift
//  Khipu
//
//  Created by Cristian Felipe Patiño Rojas on 08/04/2023.
//

import Foundation

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
