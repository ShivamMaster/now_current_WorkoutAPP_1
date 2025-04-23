swift
import SwiftUI
import Foundation
struct Settings: Codable {
    var weightUnit: String
    var notificationsEnabled: Bool
    var reminderTime: Date
    var darkModeEnabled: Bool
}
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var weightUnit: String = "kg" {
        didSet { saveSettings() }
    }
    
    @Published var notificationsEnabled: Bool = false {
        didSet { saveSettings() }
    }
    
    @Published var reminderTime: Date = Date() {
        didSet { saveSettings() }
    }
    
    @Published var darkModeEnabled: Bool = false {
        didSet { saveSettings() }
    }
    
    private init() {
        // Load settings from file or use defaults
        if let loadedSettings = SettingsManager.loadSettings() {
            self.weightUnit = loadedSettings.weightUnit
            self.notificationsEnabled = loadedSettings.notificationsEnabled
            self.reminderTime = loadedSettings.reminderTime
            self.darkModeEnabled = loadedSettings.darkModeEnabled
        } else {
            self.weightUnit = "kg"
            self.notificationsEnabled = false
            self.reminderTime = Date()
            self.darkModeEnabled = false
        }
    }
    
    private static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    private static func settingsFileURL() -> URL {
        return getDocumentsDirectory().appendingPathComponent("Settings.json")
    }
    static func loadSettings() -> Settings? {
        let url = settingsFileURL()
        
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let settings = try? decoder.decode(Settings.self, from: data) else {
            return nil
        }
        
        return settings
    }
    
    private func saveSettings() {
        let settings = Settings(weightUnit: self.weightUnit, notificationsEnabled: self.notificationsEnabled, reminderTime: self.reminderTime, darkModeEnabled: self.darkModeEnabled)
        let url = SettingsManager.settingsFileURL()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let encoded = try? encoder.encode(settings) {
            try? encoded.write(to: url)
        }
    }
}