# Consolidated Permission Request View Implementation

## Overview
Successfully consolidated all permission request views into a single unified `RequestPermissionsView` that checks permissions through both standard APIs and TCC database queries, detecting discrepancies between the two sources.

## New Files Created

### 1. Models
- **`PermissionStatusComparison.swift`**: Core model for comparing API and TCC database permission statuses
  - `PermissionStatusMatch` enum: Tracks if statuses match, mismatch, or have errors
  - `PermissionStatusComparison` struct: Stores comparison results with discrepancy detection
  - TCC service name mapping for all permission types

### 2. Services Extensions
- **`SystemService/Get/GetPermissionStatus.swift`**: Query system TCC database for specific permissions
  - `getPermissionStatus()`: Returns granted status and if entry was found
  - `getAuthValue()`: Returns raw auth_value from TCC database

- **`UserService/Get/GetPermissionStatus.swift`**: Query user TCC database for specific permissions
  - `getPermissionStatus()`: Returns granted status and if entry was found
  - `getAuthValue()`: Returns raw auth_value from TCC database

### 3. Enhanced Models
- **`ReqListModel.swift`**: Updated to include TCC database comparison
  - Added `SystemService` and `UserService` dependencies
  - Added `appBundleID` property for TCC queries
  - New methods for each permission type with comparison:
    - `checkNotificationPermissionWithComparison()`
    - `checkLocationPermissionWithComparison()`
    - `checkMicrophonePermissionWithComparison()`
    - `checkCameraPermissionWithComparison()`
    - `checkScreenRecordingPermissionWithComparison()`
    - `checkFullDiskAccessPermissionWithComparison()`
    - `checkAccessibilityPermissionWithComparison()`
    - `checkPhotosPermissionWithComparison()`
    - `checkCalendarPermissionWithComparison()`
    - `checkContactsPermissionWithComparison()`
    - `checkBluetoothPermissionWithComparison()`
    - `checkRemindersPermissionWithComparison()`
  - `checkAllPermissionsWithComparison()`: Check all permissions at once
  - Helper methods for status comparison and matching logic

### 4. ViewModel
- **`RequestPermissionsVM.swift`**: Manages permission checking and comparison state
  - `@Published` properties for UI state management
  - `loadAllPermissions()`: Load and check all permissions
  - `checkPermission()`: Check specific permission
  - `requestPermission()`: Request specific permission
  - `getDiscrepancies()`: Filter to show only mismatched permissions
  - `getStatus()`: Get status for specific permission type

### 5. View
- **`RequestPermissionsView.swift`**: Unified UI for all permission management
  - Header with status message and discrepancy count
  - "Check All Permissions" button
  - Toggle to filter discrepancies only
  - Scrollable list of permission rows
  - Each row shows:
    - Permission icon and name
    - Warning indicator if discrepancy exists
    - API status badge
    - User TCC status badge (if exists)
    - System TCC status badge (if exists)
    - Discrepancy description (if applicable)
    - Request and Refresh buttons
  - Color-coded status badges (green/yellow/red)

## Updated Files

### ContentView.swift
- Reorganized navigation with sections:
  - **Permission Management**: Features the new consolidated view prominently
  - **System Access**: Groups system-level access controls
  - **Individual Permissions (Legacy)**: Preserved old views for backward compatibility

## Features

### Core Functionality
1. **Dual Status Checking**: Checks permissions via both:
   - Standard macOS APIs (AVFoundation, Photos, EventKit, etc.)
   - Direct TCC database queries (System and User databases)

2. **Discrepancy Detection**: 
   - Automatically detects when API status doesn't match TCC database status
   - Visual warnings (⚠️) for mismatches
   - Detailed discrepancy descriptions

3. **Comprehensive Coverage**: Supports 15 permission types:
   - Notifications
   - Location
   - Microphone
   - Camera
   - Screen Recording
   - Full Disk Access
   - Accessibility
   - Files and Folders
   - Photos
   - Calendar
   - Contacts
   - Bluetooth
   - Reminders
   - Speech Recognition
   - Apple Events

4. **Real-time Updates**: Refresh individual permissions or all at once

5. **User Actions**:
   - Request permission via standard APIs
   - Refresh status to check current state
   - Filter to view only discrepancies

### TCC Service Mapping
Maps permission types to TCC service names:
- Notifications → `kTCCServiceNotifications`
- Location → `kTCCServiceLocation`
- Microphone → `kTCCServiceMicrophone`
- Camera → `kTCCServiceCamera`
- Screen Recording → `kTCCServiceScreenCapture`
- Full Disk Access → `kTCCServiceSystemPolicyAllFiles`
- Accessibility → `kTCCServiceAccessibility`
- Photos → `kTCCServicePhotos`
- Calendar → `kTCCServiceCalendar`
- Contacts → `kTCCServiceAddressBook`
- Bluetooth → `kTCCServiceBluetooth`
- Reminders → `kTCCServiceReminders`
- Apple Events → `kTCCServiceAppleEvents`

### Status Comparison Logic
- Compares normalized status strings (case-insensitive)
- Understands equivalent statuses (e.g., "Granted" ≈ "Authorized")
- Handles auth_value mappings:
  - 0 = Denied
  - 2 = Granted
  - 3 = Limited (for Photos)

### UI/UX
- Clean, modern SwiftUI design
- Color-coded status indicators
- Loading states and progress indicators
- Empty states with helpful messaging
- Responsive button states
- Accessible icons for each permission type

## Benefits

1. **Single Source of Truth**: One view for all permission management
2. **Security Monitoring**: Detect when TCC database has been tampered with
3. **Debugging Tool**: Quickly identify permission inconsistencies
4. **Better UX**: Consolidated interface instead of 15+ separate views
5. **Extensible**: Easy to add new permission types

## Usage

1. Navigate to "Request & Check Permissions" in the sidebar
2. Click "Check All Permissions" to scan all permissions
3. View status for each permission:
   - Green badges = Granted
   - Red badges = Denied
   - Yellow badges = Limited
   - Orange warning = Discrepancy detected
4. Use "Request" button to request a permission
5. Use refresh button to update status
6. Toggle "Discrepancies Only" to focus on issues

## Technical Implementation

### Architecture
- **MVVM Pattern**: Separates UI (View), business logic (ViewModel), and data (Model)
- **Async/Await**: Modern Swift concurrency for permission requests
- **Combine Framework**: Reactive UI updates with `@Published` properties
- **SQLite3**: Direct TCC database queries
- **Service Layer**: Modular permission request services

### Error Handling
- Try-catch blocks for each permission check
- Individual error handling prevents one failure from blocking others
- Error statuses displayed in comparison results

### Performance
- Lazy loading for permission list
- Individual permission checks don't block UI
- Background thread for database queries

## Next Steps (Optional Enhancements)

1. Add ability to modify TCC database directly
2. Export permission comparison reports
3. Schedule automatic permission audits
4. Add filtering by permission type
5. Implement search functionality
6. Add permission history tracking
7. Create alerts for new discrepancies
