import Foundation

struct KeyManager {
    static func getAPIKey() -> String? {
        guard let path = Bundle.main.path(forResource: "APIKeys", ofType: "plist"),
              let xml = FileManager.default.contents(atPath: path),
              let keys = try? PropertyListDecoder().decode([String: String].self, from: xml) else {
            return nil
        }
        return keys["GeminiAPIKey"]
    }
}
//
//  KeyManager.swift
//  Otracker
//
//  Created by Kev on 09/07/25.
//

