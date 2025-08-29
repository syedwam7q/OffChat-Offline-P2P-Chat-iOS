import Foundation
import UIKit

struct UserProfile: Codable {
    var displayName: String
    var status: String
    var avatarData: Data?
    var createdAt: Date
    
    init(displayName: String, status: String = "Hey there! I'm using OffChat", avatarData: Data? = nil) {
        self.displayName = displayName
        self.status = status
        self.avatarData = avatarData
        self.createdAt = Date()
    }
    
    func avatarImage() -> UIImage? {
        guard let data = avatarData else { return nil }
        return UIImage(data: data)
    }
    
    mutating func setAvatarImage(_ image: UIImage?) {
        if let image = image, let data = image.jpegData(compressionQuality: 0.8) {
            self.avatarData = data
        } else {
            self.avatarData = nil
        }
    }
    
    func initials() -> String {
        let components = displayName.components(separatedBy: .whitespacesAndNewlines)
        let initials = components.compactMap { $0.first }.prefix(2)
        return String(initials).uppercased()
    }
}

// Profile Manager
final class ProfileManager {
    static let shared = ProfileManager()
    private let profileKey = "offchat_user_profile"
    private let queue = DispatchQueue(label: "ProfileManager.queue", qos: .userInitiated)
    
    private init() {}
    
    private var _currentProfile: UserProfile?
    
    var currentProfile: UserProfile? {
        if let profile = _currentProfile {
            return profile
        }
        _currentProfile = loadProfile()
        return _currentProfile
    }
    
    var isProfileSetup: Bool {
        guard let profile = currentProfile else { return false }
        return !profile.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func saveProfile(_ profile: UserProfile, completion: (() -> Void)? = nil) {
        queue.async { [weak self] in
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            if let data = try? encoder.encode(profile) {
                UserDefaults.standard.set(data, forKey: self?.profileKey ?? "")
                DispatchQueue.main.async {
                    self?._currentProfile = profile
                    completion?()
                }
            } else {
                DispatchQueue.main.async {
                    completion?()
                }
            }
        }
    }
    
    private func loadProfile() -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: profileKey) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(UserProfile.self, from: data)
    }
    
    func updateProfile(name: String? = nil, status: String? = nil, avatar: UIImage? = nil, completion: (() -> Void)? = nil) {
        guard var profile = currentProfile else { 
            completion?()
            return 
        }
        
        if let name = name { profile.displayName = name }
        if let status = status { profile.status = status }
        if let avatar = avatar { profile.setAvatarImage(avatar) }
        
        saveProfile(profile, completion: completion)
    }
    
    func deleteProfile() {
        UserDefaults.standard.removeObject(forKey: profileKey)
        _currentProfile = nil
    }
}