import Foundation

/// Example context data structure for demonstrating arbitrary data sharing
public struct UserContext: Codable, Sendable {
    public let userID: String
    public let username: String
    public let deviceInfo: DeviceInfo
    public let sessionStartTime: Date
    
    public init(userID: String, username: String, deviceInfo: DeviceInfo, sessionStartTime: Date = Date()) {
        self.userID = userID
        self.username = username
        self.deviceInfo = deviceInfo
        self.sessionStartTime = sessionStartTime
    }
}

public struct DeviceInfo: Codable, Sendable {
    public let deviceModel: String
    public let osVersion: String
    public let appVersion: String
    
    public init(deviceModel: String, osVersion: String, appVersion: String) {
        self.deviceModel = deviceModel
        self.osVersion = osVersion
        self.appVersion = appVersion
    }
}