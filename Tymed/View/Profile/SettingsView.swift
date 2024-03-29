//
//  SettingsView.swift
//  Tymed
//
//  Created by Jonah Schueller on 25.08.20.
//  Copyright © 2020 Jonah Schueller. All rights reserved.
//

import SwiftUI

//MARK: SettingsView
struct SettingsView: View {
    
    @State
    private var useICloud = false
    
    @State
    private var notificationOffset: NotificationOffset? = SettingsService.shared.notificationOffset
    
    @State
    private var autoArchive: SettingsService.TaskAutoArchiveDelay? = SettingsService.shared.taskAutoArchivingDelay
    
    var body: some View {
        List {
            
            Section(header: Text("App Icon")) {
                NavigationLink(destination: AppIconPicker()) {
                    DetailCellDescriptor("App Icon", image: "app", .systemBlue)
                }
            }
            
            Section(header: Text("Notifications")) {
                HStack {
                    DetailCellDescriptor("Send lesson reminders", image: "paperplane.fill", .systemGreen)
                    Toggle("", isOn: $useICloud)
                        .labelsHidden()
                }
                
                Picker("Sound", selection: $useICloud) {
                    List {
                        Text("My sounds")
                    }
                }.font(.system(size: 14, weight: .semibold))
                
                HStack {
                    DetailCellDescriptor("Send task reminders", image: "list.dash", .systemOrange)
                    Toggle("", isOn: $useICloud)
                        .labelsHidden()
                }
                
                Picker("Sound", selection: $useICloud) {
                    List {
                        Text("My sounds")
                    }
                }.font(.system(size: 14, weight: .semibold))
                
                HStack {
                    DetailCellDescriptor("Other notifications", image: "app.badge", .systemPurple)
                    Toggle("", isOn: $useICloud)
                        .labelsHidden()
                }
                
                Picker("Sound", selection: $useICloud) {
                    List {
                        Text("My sounds")
                    }
                }.font(.system(size: 14, weight: .semibold))
                
            }
            
            Section (header: Text("Default values")) {
                
                HStack {
                    NavigationLink (destination: NotificationOffsetView(notificationOffset: $notificationOffset)) {
                        DetailCellDescriptor("Default notification offset",
                                             image: "bell.badge.fill",
                                             .systemGreen,
                                             value: defaultNotificationOffset())
                    }
                }
                
                NavigationLink (destination: AutoArchiveDelayTaskPickerView(autoArchiveDelay: $autoArchive)) {
                    DetailCellDescriptor("Auto archive tasks",
                                         image: "tray.full.fill",
                                         .systemOrange,
                                         value: autoArchiveTasks())
                }
                
            }
            
            Section (header: Text("Storage")) {
                HStack {
                    DetailCellDescriptor("Use iCloud", image: "cloud.fill", .systemBlue)
                    Toggle("", isOn: $useICloud)
                        .labelsHidden()
                }
            }
            
            Section (header: Text("Danger zone")) {
                DetailCellDescriptor("Reset the app", image: "trash.fill", .systemRed)
                    .padding(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 11)
                            .stroke(Color(.systemRed), lineWidth: 4)
                    )
            }.listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            
        }.listStyle(InsetGroupedListStyle())
        .navigationBarTitle("Settings")
        .onChange(of: notificationOffset) { (value) in
            SettingsService.shared.notificationOffset = notificationOffset
        }.onChange(of: autoArchive, perform: { (value) in
            SettingsService.shared.taskAutoArchivingDelay = autoArchive
        })
        .onAppear {
            
        }
    }
    
    private func defaultNotificationOffset() -> String {
        guard let value = notificationOffset else {
            return "-"
        }
        return value.title
    }
    
    private func autoArchiveTasks() -> String {
        guard let value = autoArchive else {
            return "Never"
        }
        return value.title
    }
}

//MARK: AutoArchiveDelayTaskPickerView
struct AutoArchiveDelayTaskPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @Binding
    var autoArchiveDelay: SettingsService.TaskAutoArchiveDelay?
    
    var body: some View {
        List {
            
            Section(header: Text("Info")) {
                
                Text("The app can automatically archive tasks with an expired due date. You can select how much time has to pass after the due date expires until the task is automatically archived.")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.vertical)
                
            }
            
            HStack {
                Text("Never")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                
                if autoArchiveDelay == nil {
                    Image(systemName: "checkmark")
                        .foregroundColor(Color(.systemBlue))
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .contentShape(Rectangle())
            .frame(height: 45)
            .onTapGesture {
                autoArchiveDelay = nil
            }
            
            ForEach(SettingsService.TaskAutoArchiveDelay.allCases, id: \.delay) { delay in
                HStack {
                    Text(delay.title)
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    
                    if delay == autoArchiveDelay {
                        Image(systemName: "checkmark")
                            .foregroundColor(Color(.systemBlue))
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .contentShape(Rectangle())
                .frame(height: 45)
                .onTapGesture {
                    autoArchiveDelay = delay
                }
            }
            
        }.listStyle(InsetGroupedListStyle())
        .navigationTitle("Task auto archiving")
    }

}

struct AppIconPicker: View {
    
    @State
    var currentIcon = UIApplication.shared.alternateIconName
    
    private var appIcons = ["Light", "Dark"]
    
    var body: some View {
        
        List {
            
            ForEach(appIcons, id: \.self) { icon in
                HStack {
                    Image("AppLogo-\(icon)")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .cornerRadius(12)
                        .aspectRatio(contentMode: .fit)
                        .padding(.trailing)
                    Text(icon)
                        .font(.system(size: 15, weight: .semibold))
                    Spacer()
                    
                    if "AppIcon_\(icon)" == currentIcon {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(.systemBlue))
                            .font(.system(size: 20, weight: .semibold))
                    }
                }.contentShape(Rectangle())
                .onTapGesture {
                    currentIcon = "AppIcon_\(icon)"
                    UIApplication.shared.setAlternateIconName(currentIcon) { error in
                        if let error = error {
                            print(error.localizedDescription)
                        } else {
                            print("Success!")
                        }
                    }
                    currentIcon = UIApplication.shared.alternateIconName
                }.padding(.vertical)
            }
            
        }.navigationTitle("App Icon")
        .listStyle(InsetGroupedListStyle())
        
    }
    
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
