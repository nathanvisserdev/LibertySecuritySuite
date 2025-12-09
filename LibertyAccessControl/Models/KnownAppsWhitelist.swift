//
//  KnownAppsWhitelist.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation

struct AppPermissionProfile {
    let bundleID: String
    let appName: String
    let allowedServices: Set<String>
    let description: String
}

/// Whitelist of known legitimate apps and their expected permissions
class KnownAppsWhitelist {
    static let shared = KnownAppsWhitelist()
    
    private lazy var profiles: [String: AppPermissionProfile] = {
        // Build the profiles dictionary lazily
        var profilesDict: [String: AppPermissionProfile] = [:]
        
        // Apple System Apps
        let appleApps = [
            AppPermissionProfile(
                bundleID: "com.apple.Safari",
                appName: "Safari",
                allowedServices: [
                    "kTCCServiceCamera",
                    "kTCCServiceMicrophone",
                    "kTCCServiceScreenCapture",
                    "kTCCServiceLocation",
                    "kTCCServiceUserTracking"
                ],
                description: "Web browser - needs media access for web conferencing"
            ),
            AppPermissionProfile(
                bundleID: "com.apple.FaceTime",
                appName: "FaceTime",
                allowedServices: [
                    "kTCCServiceCamera",
                    "kTCCServiceMicrophone",
                    "kTCCServiceAddressBook"
                ],
                description: "Video calling app"
            ),
            AppPermissionProfile(
                bundleID: "com.apple.iCal",
                appName: "Calendar",
                allowedServices: [
                    "kTCCServiceCalendar",
                    "kTCCServiceReminders",
                    "kTCCServiceAddressBook"
                ],
                description: "Calendar and events management"
            ),
            AppPermissionProfile(
                bundleID: "com.apple.Mail",
                appName: "Mail",
                allowedServices: [
                    "kTCCServiceAddressBook",
                    "kTCCServiceCalendar",
                    "kTCCServiceSystemPolicyAllFiles",
                    "kTCCServiceSystemPolicyDesktopFolder",
                    "kTCCServiceSystemPolicyDocumentsFolder",
                    "kTCCServiceSystemPolicyDownloadsFolder"
                ],
                description: "Email client"
            ),
            AppPermissionProfile(
                bundleID: "com.apple.Photos",
                appName: "Photos",
                allowedServices: [
                    "kTCCServicePhotos",
                    "kTCCServicePhotoAdd",
                    "kTCCServiceMediaLibrary",
                    "kTCCServiceSystemPolicyAllFiles",
                    "kTCCServiceSystemPolicyDesktopFolder",
                    "kTCCServiceSystemPolicyDocumentsFolder",
                    "kTCCServiceSystemPolicyDownloadsFolder"
                ],
                description: "Photo library management"
            ),
            AppPermissionProfile(
                bundleID: "com.apple.Contacts",
                appName: "Contacts",
                allowedServices: [
                    "kTCCServiceAddressBook"
                ],
                description: "Contact management"
            ),
            AppPermissionProfile(
                bundleID: "com.apple.finder",
                appName: "Finder",
                allowedServices: [
                    "kTCCServiceSystemPolicyAllFiles",
                    "kTCCServiceSystemPolicyDesktopFolder",
                    "kTCCServiceSystemPolicyDocumentsFolder",
                    "kTCCServiceSystemPolicyDownloadsFolder",
                    "kTCCServiceSystemPolicyNetworkVolumes",
                    "kTCCServiceSystemPolicyRemovableVolumes"
                ],
                description: "File system browser"
            )
        ]
        
        // Communication Apps
        let communicationApps = [
            AppPermissionProfile(
                bundleID: "com.microsoft.teams",
                appName: "Microsoft Teams",
                allowedServices: [
                    "kTCCServiceCamera",
                    "kTCCServiceMicrophone",
                    "kTCCServiceScreenCapture",
                    "kTCCServiceAddressBook",
                    "kTCCServiceCalendar"
                ],
                description: "Business communication platform"
            ),
            AppPermissionProfile(
                bundleID: "us.zoom.xos",
                appName: "Zoom",
                allowedServices: [
                    "kTCCServiceCamera",
                    "kTCCServiceMicrophone",
                    "kTCCServiceScreenCapture",
                    "kTCCServiceAccessibility"
                ],
                description: "Video conferencing"
            ),
            AppPermissionProfile(
                bundleID: "com.tinyspeck.slackmacgap",
                appName: "Slack",
                allowedServices: [
                    "kTCCServiceCamera",
                    "kTCCServiceMicrophone",
                    "kTCCServiceScreenCapture",
                    "kTCCServiceSystemPolicyDesktopFolder",
                    "kTCCServiceSystemPolicyDocumentsFolder",
                    "kTCCServiceSystemPolicyDownloadsFolder"
                ],
                description: "Team collaboration platform"
            ),
            AppPermissionProfile(
                bundleID: "com.cisco.webex.meetings",
                appName: "Webex",
                allowedServices: [
                    "kTCCServiceCamera",
                    "kTCCServiceMicrophone",
                    "kTCCServiceScreenCapture",
                    "kTCCServiceAccessibility"
                ],
                description: "Video conferencing"
            ),
            AppPermissionProfile(
                bundleID: "com.skype.skype",
                appName: "Skype",
                allowedServices: [
                    "kTCCServiceCamera",
                    "kTCCServiceMicrophone",
                    "kTCCServiceAddressBook"
                ],
                description: "Voice and video calls"
            )
        ]
        
        // Development Tools
        let developmentApps = [
            AppPermissionProfile(
                bundleID: "com.apple.dt.Xcode",
                appName: "Xcode",
                allowedServices: [
                    "kTCCServiceSystemPolicyAllFiles",
                    "kTCCServiceSystemPolicyDesktopFolder",
                    "kTCCServiceSystemPolicyDocumentsFolder",
                    "kTCCServiceSystemPolicyDownloadsFolder",
                    "kTCCServiceDeveloperTool",
                    "kTCCServiceEndpointSecurityClient"
                ],
                description: "Apple's IDE for software development"
            ),
            AppPermissionProfile(
                bundleID: "com.microsoft.VSCode",
                appName: "Visual Studio Code",
                allowedServices: [
                    "kTCCServiceSystemPolicyAllFiles",
                    "kTCCServiceSystemPolicyDesktopFolder",
                    "kTCCServiceSystemPolicyDocumentsFolder",
                    "kTCCServiceSystemPolicyDownloadsFolder",
                    "kTCCServiceAccessibility"
                ],
                description: "Code editor"
            ),
            AppPermissionProfile(
                bundleID: "com.apple.Terminal",
                appName: "Terminal",
                allowedServices: [
                    "kTCCServiceSystemPolicyAllFiles",
                    "kTCCServiceSystemPolicyDesktopFolder",
                    "kTCCServiceSystemPolicyDocumentsFolder",
                    "kTCCServiceSystemPolicyDownloadsFolder",
                    "kTCCServiceAccessibility",
                    "kTCCServiceDeveloperTool"
                ],
                description: "Command line interface"
            ),
            AppPermissionProfile(
                bundleID: "com.googlecode.iterm2",
                appName: "iTerm2",
                allowedServices: [
                    "kTCCServiceSystemPolicyAllFiles",
                    "kTCCServiceSystemPolicyDesktopFolder",
                    "kTCCServiceSystemPolicyDocumentsFolder",
                    "kTCCServiceSystemPolicyDownloadsFolder",
                    "kTCCServiceAccessibility"
                ],
                description: "Terminal emulator"
            )
        ]
        
        // Browsers
        let browsers = [
            AppPermissionProfile(
                bundleID: "com.google.Chrome",
                appName: "Google Chrome",
                allowedServices: [
                    "kTCCServiceCamera",
                    "kTCCServiceMicrophone",
                    "kTCCServiceScreenCapture",
                    "kTCCServiceLocation",
                    "kTCCServiceUserTracking",
                    "kTCCServiceSystemPolicyDesktopFolder",
                    "kTCCServiceSystemPolicyDocumentsFolder",
                    "kTCCServiceSystemPolicyDownloadsFolder"
                ],
                description: "Web browser"
            ),
            AppPermissionProfile(
                bundleID: "org.mozilla.firefox",
                appName: "Firefox",
                allowedServices: [
                    "kTCCServiceCamera",
                    "kTCCServiceMicrophone",
                    "kTCCServiceScreenCapture",
                    "kTCCServiceLocation",
                    "kTCCServiceSystemPolicyDesktopFolder",
                    "kTCCServiceSystemPolicyDocumentsFolder",
                    "kTCCServiceSystemPolicyDownloadsFolder"
                ],
                description: "Web browser"
            ),
            AppPermissionProfile(
                bundleID: "com.brave.Browser",
                appName: "Brave",
                allowedServices: [
                    "kTCCServiceCamera",
                    "kTCCServiceMicrophone",
                    "kTCCServiceScreenCapture",
                    "kTCCServiceLocation",
                    "kTCCServiceSystemPolicyDesktopFolder",
                    "kTCCServiceSystemPolicyDocumentsFolder",
                    "kTCCServiceSystemPolicyDownloadsFolder"
                ],
                description: "Privacy-focused web browser"
            )
        ]
        
        // Productivity
        let productivityApps = [
            AppPermissionProfile(
                bundleID: "com.microsoft.Word",
                appName: "Microsoft Word",
                allowedServices: [
                    "kTCCServiceSystemPolicyAllFiles",
                    "kTCCServiceSystemPolicyDesktopFolder",
                    "kTCCServiceSystemPolicyDocumentsFolder",
                    "kTCCServiceSystemPolicyDownloadsFolder",
                    "kTCCServicePhotos"
                ],
                description: "Word processor"
            ),
            AppPermissionProfile(
                bundleID: "com.microsoft.Excel",
                appName: "Microsoft Excel",
                allowedServices: [
                    "kTCCServiceSystemPolicyAllFiles",
                    "kTCCServiceSystemPolicyDesktopFolder",
                    "kTCCServiceSystemPolicyDocumentsFolder",
                    "kTCCServiceSystemPolicyDownloadsFolder"
                ],
                description: "Spreadsheet application"
            ),
            AppPermissionProfile(
                bundleID: "com.adobe.Photoshop",
                appName: "Adobe Photoshop",
                allowedServices: [
                    "kTCCServiceSystemPolicyAllFiles",
                    "kTCCServiceSystemPolicyDesktopFolder",
                    "kTCCServiceSystemPolicyDocumentsFolder",
                    "kTCCServiceSystemPolicyDownloadsFolder",
                    "kTCCServicePhotos",
                    "kTCCServiceCamera"
                ],
                description: "Image editing software"
            ),
            AppPermissionProfile(
                bundleID: "com.apple.iWork.Pages",
                appName: "Pages",
                allowedServices: [
                    "kTCCServiceSystemPolicyDesktopFolder",
                    "kTCCServiceSystemPolicyDocumentsFolder",
                    "kTCCServiceSystemPolicyDownloadsFolder",
                    "kTCCServicePhotos"
                ],
                description: "Word processor"
            )
        ]
        
        // Security & Utilities
        let securityApps = [
            AppPermissionProfile(
                bundleID: "com.1password.1password",
                appName: "1Password",
                allowedServices: [
                    "kTCCServiceAccessibility",
                    "kTCCServiceSystemPolicyDesktopFolder",
                    "kTCCServiceSystemPolicyDocumentsFolder"
                ],
                description: "Password manager"
            ),
            AppPermissionProfile(
                bundleID: "com.getdropbox.dropbox",
                appName: "Dropbox",
                allowedServices: [
                    "kTCCServiceSystemPolicyAllFiles",
                    "kTCCServiceSystemPolicyDesktopFolder",
                    "kTCCServiceSystemPolicyDocumentsFolder",
                    "kTCCServiceSystemPolicyDownloadsFolder",
                    "kTCCServicePhotos",
                    "kTCCServiceAccessibility"
                ],
                description: "Cloud storage"
            ),
            AppPermissionProfile(
                bundleID: "com.apple.backup.launcher",
                appName: "Time Machine",
                allowedServices: [
                    "kTCCServiceSystemPolicyAllFiles",
                    "kTCCServiceSystemPolicyRemovableVolumes",
                    "kTCCServiceSystemPolicyNetworkVolumes"
                ],
                description: "Backup utility"
            )
        ]
        
        // Combine all profiles
        let allApps = appleApps + communicationApps + developmentApps + browsers + productivityApps + securityApps
        
        for profile in allApps {
            profilesDict[profile.bundleID] = profile
        }
        
        return profilesDict
    }()
    
    private init() {}
    
    // MARK: - Public Methods
    
    func getProfile(for bundleID: String) -> AppPermissionProfile? {
        return profiles[bundleID]
    }
    
    func isKnownApp(_ bundleID: String) -> Bool {
        return profiles[bundleID] != nil
    }
    
    func isPermissionAllowed(bundleID: String, service: String) -> Bool {
        guard let profile = profiles[bundleID] else {
            // Unknown app - not in whitelist
            return false
        }
        return profile.allowedServices.contains(service)
    }
    
    func getAllProfiles() -> [AppPermissionProfile] {
        return Array(profiles.values).sorted { $0.appName < $1.appName }
    }
    
    func getUnauthorizedPermissions(bundleID: String, grantedServices: Set<String>) -> Set<String> {
        guard let profile = profiles[bundleID] else {
            // Unknown app - all permissions are unauthorized
            return grantedServices
        }
        
        return grantedServices.subtracting(profile.allowedServices)
    }
}
