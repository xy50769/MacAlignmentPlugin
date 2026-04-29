import AppKit
import Foundation

final class LayoutStore {
    private let fileURL: URL

    init() {
        let supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
        let appDirectory = supportDirectory.appendingPathComponent("MacAlignmentPlugin", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        fileURL = appDirectory.appendingPathComponent("layouts.json")
    }

    func load() -> [LayoutTemplate] {
        guard let data = try? Data(contentsOf: fileURL) else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([LayoutTemplate].self, from: data)) ?? []
    }

    func save(_ layouts: [LayoutTemplate]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(layouts) else {
            return
        }
        try? data.write(to: fileURL, options: .atomic)
    }
}
