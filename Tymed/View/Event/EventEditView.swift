//
//  EventEditView.swift
//  Tymed
//
//  Created by Jonah Schueller on 15.09.20.
//  Copyright © 2020 Jonah Schueller. All rights reserved.
//

import SwiftUI
import EventKit

struct EventEditView: View {
    
    @ObservedObject
    var event: EventViewModel
    
    @State
    var showDiscardWarning = false
    
    @Environment(\.presentationMode)
    var presentationMode
    
    var body: some View {
        NavigationView {
            EventEditViewContent(event: event) {
                presentationMode.wrappedValue.dismiss()
            }
                .navigationTitle("Event")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(leading: Button(action: {
                    cancel()
                }, label: {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .semibold))
                }), trailing: Button(action: {
                    event.save()
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold))
                }).disabled(!event.hasChanges || event.title.isEmpty))
        }.actionSheet(isPresented: $showDiscardWarning, content: {
            ActionSheet(title: Text("Do you want to discard your changes?"), message: nil, buttons: [
                .destructive(Text("Discard changes"), action: {
                    event.rollback()
                    presentationMode.wrappedValue.dismiss()
                }),
                .cancel()
            ])
        })
    }
    
    func cancel() {
        if event.hasChanges {
            showDiscardWarning.toggle()
        }else {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct EventEditViewContent: View {
    
    @ObservedObject
    var event: EventViewModel
    
    @Environment(\.presentationMode)
    var presentationMode
    
    @State
    private var showStartDatePicker = false
    
    @State
    private var showEndDatePicker = false
    
    @State
    private var showNotificationDatePicker = false

    //MARK: Delete state
    @State var showDeleteAction = false
    
    @State
    private var duration: TimeInterval = 3600
    
    var dismiss: () -> Void
    
    var body: some View {
        List {
            
            Section {
                
                TextField("Title", text: $event.title)
                
            }
            
            Section {
                
                DetailCellDescriptor("Start date", image: "calendar", .systemBlue, value: textFor(event.startDate))
                    .onTapGesture {
                        withAnimation {
                            showStartDatePicker.toggle()
                            
                            if showEndDatePicker {
                                showEndDatePicker = false
                            }
                        }
                    }
                
                if showStartDatePicker {
                    DatePicker("", selection: $event.startDate)
                        .datePickerStyle(GraphicalDatePickerStyle())
                }
                
                DetailCellDescriptor("End date", image: "calendar", .systemOrange, value: textFor(event.endDate))
                    .animation(.default)
                    .onTapGesture {
                        withAnimation {
                            showEndDatePicker.toggle()
                            
                            if showStartDatePicker {
                                showStartDatePicker = false
                            }
                        }
                    }
                
                if showEndDatePicker {
                    DatePicker("", selection: $event.endDate, in: (event.startDate + 60)...)
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .animation(.default)
                }
                
//                HStack {
//                    DetailCellDescriptor("Notification", image: "app.badge", .systemGreen, value: textForNotification())
//                    Toggle("", isOn: Binding(isNotNil: $event.notificationDate, defaultValue: Date()))
//                }.animation(.default)
//                .onTapGesture {
//                    withAnimation {
//                        showNotificationDatePicker.toggle()
//                    }
//                }
    
//                if event.notificationDate != nil && showNotificationDatePicker {
//                    DatePicker("", selection: Binding($event.notificationDate)!, in: Date()...)
//                        .datePickerStyle(GraphicalDatePickerStyle())
//                        .animation(.easeIn)
//                }
                
                HStack {
                    DetailCellDescriptor("All day", image: "clock.arrow.circlepath", .systemBlue)
                    Toggle("", isOn: $event.isAllDay)
                }
            }
            
            //MARK: Calendar
            
//            Section {
//                HStack {
//
//                    NavigationLink(destination: AppTimetablePicker(timetable: $event.timetable)) {
//                        DetailCellDescriptor("Calendar", image: "tray.full.fill", .systemRed, value: timetableTitle())
//                        Spacer()
//                        if event.timetable == TimetableService.shared.defaultTimetable() {
//                            Text("Default")
//                                .padding(EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10))
//                                .background(Color(.tertiarySystemGroupedBackground))
//                                .font(.system(size: 13, weight: .semibold))
//                                .cornerRadius(10)
//                        }
//                    }
//
//                }
//            }
            
            //MARK: Delete
            Section {
                DetailCellDescriptor("Delete", image: "trash.fill", .systemRed)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showDeleteAction.toggle()
                    }.actionSheet(isPresented: $showDeleteAction) {
                        ActionSheet(
                            title: Text(""),
                            message: nil,
                            buttons: [
                                .destructive(Text("Delete"), action: {
                                    deleteEvent()
                                }),
                                .cancel()
                            ])
                    }
            }
            
        }.listStyle(InsetGroupedListStyle())
        .onChange(of: event.endDate) { value in
            if let start = event.startDate,
               let end = event.endDate {
                duration = end.timeIntervalSince(start)
            }
        }.onChange(of: event.startDate) { value in
            guard let start = event.startDate else {
                return
            }
            event.endDate = start + duration
        }.onAppear {
            if let start = event.startDate,
               let end = event.endDate {
                duration = end.timeIntervalSince(start)
            }
        }
    }

    func textFor(_ date: Date?) -> String {
        return date?.stringify(dateStyle: .long, timeStyle: .short)  ?? ""
    }

    //MARK: timetableTitle
    private func timetableTitle() -> String? {
        return event.calendar.title
    }
    
//    private func textForNotification() -> String? {
//        return event.notificationDate?.stringify(dateStyle: .medium, timeStyle: .short)
//    }
    
    //MARK: deleteEvent
    private func deleteEvent() {
        showDeleteAction = false
        dismiss()
        
    }
}
