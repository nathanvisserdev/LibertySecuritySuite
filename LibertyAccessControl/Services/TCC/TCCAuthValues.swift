//
//  TCCAuthValues.swift
//  LibertyAccessControl
//
//  Reference file for TCC auth_value meanings
//

/*
 TCC Database auth_value Reference
 
 The auth_value field in the TCC database access table indicates the authorization status:
 
 0 = Denied
     - User explicitly denied permission
     - App is blocked from accessing the resource
 
 1 = Unknown/Error
     - Rare state, usually indicates an error or uninitialized state
 
 2 = Allowed/Granted
     - User granted full permission
     - App has complete access to the resource
 
 3 = Limited
     - Partial access granted (primarily used for Photos)
     - User selected "Limited Photos Access"
     - App can only access specific photos
 
 4 = Hybrid (rare)
     - Used in some edge cases for partial permissions
 
 Note: Different macOS versions may introduce new auth_value meanings.
 Always test permission status on target OS versions.
 
 TCC Service Names
 -----------------
 Common service strings found in the TCC database:
 
 - kTCCServiceNotifications          - Notification permissions
 - kTCCServiceLocation               - Location Services
 - kTCCServiceMicrophone             - Microphone access
 - kTCCServiceCamera                 - Camera access
 - kTCCServiceScreenCapture          - Screen Recording
 - kTCCServiceSystemPolicyAllFiles   - Full Disk Access
 - kTCCServiceAccessibility          - Accessibility permissions
 - kTCCServicePhotos                 - Photo Library access
 - kTCCServiceCalendar               - Calendar access
 - kTCCServiceAddressBook            - Contacts access
 - kTCCServiceBluetooth              - Bluetooth permissions
 - kTCCServiceReminders              - Reminders access
 - kTCCServiceAppleEvents            - Apple Events/Automation
 - kTCCServiceSystemPolicyDesktopFolder    - Desktop folder access
 - kTCCServiceSystemPolicyDocumentsFolder  - Documents folder access
 - kTCCServiceSystemPolicyDownloadsFolder  - Downloads folder access
 - kTCCServiceSystemPolicyNetworkVolumes   - Network volumes access
 - kTCCServiceSystemPolicyRemovableVolumes - Removable volumes access
 
 Client Types
 ------------
 The client_type field indicates what kind of entity is requesting access:
 
 0 = Bundle ID (most common for apps)
 1 = Absolute path to executable
 
 Auth Reason
 -----------
 The auth_reason field indicates how the permission was granted:
 
 1 = Error
 2 = User Consent (user clicked Allow)
 3 = User Set (manually configured)
 4 = System Set (set by system or MDM)
 5 = Service Policy (determined by service policy)
 6 = MDM Policy (set by Mobile Device Management)
 
*/
