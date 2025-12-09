//
//  ContentView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import SwiftUI

struct ContentView: View {

    var body: some View {
        NavigationSplitView {
            List {
                NavigationLink {
                    HomeView()
                } label: {
                    Label("Home", systemImage: "house.fill")
                }
                
                NavigationLink {
                    DashboardView()
                } label: {
                    Label("Permissions", systemImage: "checklist")
                }
                
                NavigationLink {
                    AppPermissionsView()
                } label: {
                    Label("App Permissions", systemImage: "checkmark.shield.fill")
                }
                
                NavigationLink {
                    BlacklistManagementView()
                } label: {
                    Label("Blacklist Management", systemImage: "hand.raised.fill")
                }
                
                NavigationLink {
                    SecurityMonitorView()
                } label: {
                    Label("Security Monitor", systemImage: "shield.checkered")
                }
                
                NavigationLink {
                    MonitoringPreferencesView()
                } label: {
                    Label("Monitoring Preferences", systemImage: "slider.horizontal.3")
                }
                
                Section("Permission Management") {
                    NavigationLink {
                        RequestPermissionsView()
                    } label: {
                        Label("Request & Check Permissions", systemImage: "lock.shield.fill")
                    }
                    
                    NavigationLink {
                        ReqListView()
                    } label: {
                        Label("Request List (Legacy)", systemImage: "list.bullet.rectangle")
                    }
                }
                
                Section("System Access") {
                    NavigationLink {
                        AllowRemoteFileAccessView()
                    } label: {
                        Label("Grant Remote File Access", systemImage: "shield.checkered")
                    }
                    
                    NavigationLink {
                        ScreenSharingView()
                    } label: {
                        Label("Screen Sharing", systemImage: "rectangle.on.rectangle")
                    }
                    
                    NavigationLink {
                        RemoteManagementView()
                    } label: {
                        Label("Remote Management", systemImage: "desktopcomputer")
                    }
                    
                    NavigationLink {
                        SSHView()
                    } label: {
                        Label("SSH Access", systemImage: "terminal.fill")
                    }
                }
                
                Section("Individual Permissions (Legacy)") {
                    NavigationLink {
                        LocationView()
                    } label: {
                        Label("Location", systemImage: "location.fill")
                    }
                    
                    NavigationLink {
                        MicrophoneView()
                    } label: {
                        Label("Microphone", systemImage: "mic.fill")
                    }
                    
                    NavigationLink {
                        CameraView()
                    } label: {
                        Label("Camera", systemImage: "camera.fill")
                    }
                    
                    NavigationLink {
                        ScreenRecordingView()
                    } label: {
                        Label("Screen Recording", systemImage: "record.circle.fill")
                    }
                    
                    NavigationLink {
                        FullDiskAccessView()
                    } label: {
                        Label("Full Disk Access", systemImage: "internaldrive.fill")
                    }
                    
                    NavigationLink {
                        AccessibilityView()
                    } label: {
                        Label("Accessibility", systemImage: "accessibility.fill")
                    }
                    
                    NavigationLink {
                        FilesAndFoldersView()
                    } label: {
                        Label("Files and Folders", systemImage: "folder.fill")
                    }
                    
                    NavigationLink {
                        PhotosView()
                    } label: {
                        Label("Photos", systemImage: "photo.fill")
                    }
                    
                    NavigationLink {
                        CalendarView()
                    } label: {
                        Label("Calendar", systemImage: "calendar")
                    }
                    
                    NavigationLink {
                        ContactsView()
                    } label: {
                        Label("Contacts", systemImage: "person.crop.circle.fill")
                    }
                    
                    NavigationLink {
                        BluetoothView()
                    } label: {
                        Label("Bluetooth", systemImage: "dot.radiowaves.left.and.right")
                    }
                    
                    NavigationLink {
                        RemindersView()
                    } label: {
                        Label("Reminders", systemImage: "checklist")
                    }
                    
                    NavigationLink {
                        SpeechRecognitionView()
                    } label: {
                        Label("Speech Recognition", systemImage: "waveform")
                    }
                    
                    NavigationLink {
                        AppleEventsView()
                    } label: {
                        Label("Apple Events", systemImage: "applescript.fill")
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            HomeView()
        }
    }
}

#Preview {
    ContentView()
}
