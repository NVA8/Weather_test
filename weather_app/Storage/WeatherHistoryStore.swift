//
//  WeatherHistoryStore.swift
//  weather_app
//
//  Created by Valeriy Nikitin on 2023-10-08.
//

import Foundation

protocol WeatherHistoryStoreProtocol {
    func load() throws -> [WeatherHistoryEntry]
    func save(_ history: [WeatherHistoryEntry]) throws
}

struct WeatherHistoryStore: WeatherHistoryStoreProtocol {
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    init(fileName: String = "weather-history.json") {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = documents.appendingPathComponent(fileName)
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    func load() throws -> [WeatherHistoryEntry] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode([WeatherHistoryEntry].self, from: data)
    }
    
    func save(_ history: [WeatherHistoryEntry]) throws {
        let data = try encoder.encode(history)
        try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
    }
}
