//
//  EventEditView.swift
//  Tymed
//
//  Created by Jonah Schueller on 15.09.20.
//  Copyright © 2020 Jonah Schueller. All rights reserved.
//

import SwiftUI

class EventEditViewWrapper: ViewWrapper<EventEditView> {
    
    var event: Event?
    
    var eventEditView: EventEditView?
    
    override func createContent() -> UIHostingController<EventEditView>? {
        guard let event = event else {
            return nil
        }
        
        eventEditView = EventEditView(
            event: event,
            presentationDelegate: presentationDelegate,
            presentationHandler: presentationHandler)
     
        return UIHostingController(rootView: eventEditView!)
    }
    
}

struct EventEditView: View {
    
    @ObservedObject
    var event: Event
    
    var presentationDelegate: ViewWrapperPresentationDelegate?
    
    @ObservedObject
    var presentationHandler: ViewWrapperPresentationHandler
    
    var body: some View {
        NavigationView {
            EventEditViewContent(event: event)
                .navigationTitle("Event")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(leading: Button(action: {
                    cancel()
                }, label: {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .semibold))
                }), trailing: Button(action: {
                    NotificationService.current.scheduleEventNotification(for: event)
                    presentationDelegate?.done()
                }, label: {
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold))
                }))
        }.actionSheet(isPresented: $presentationHandler.showDiscardWarning, content: {
            ActionSheet(title: Text("Do you want to discard your changes?"), message: nil, buttons: [
                .destructive(Text("Discard changes"), action: {
                    presentationDelegate?.cancel()
                }),
                .cancel()
            ])
        })
    }
    
    func cancel() {
        if TimetableService.shared.hasChanges() {
            presentationHandler.showDiscardWarning.toggle()
        }else {
            presentationDelegate?.cancel()
        }
    }
}

struct EventEditViewContent: View {
    
    @ObservedObject
    var event: Event
    
    @State
    private var showStartDatePicker = false
    
    @State
    private var showEndDatePicker = false
    
    @State
    private var showNotificationDatePicker = false

    
    var body: some View {
        List {
            
            Section {
                
                TextField("Title", text: $event.title)
                
                TextField("Description", text: Binding($event.body, replacingNilWith: ""))
            }
            
            Section {
                
                DetailCellDescriptor("Start date", image: "calendar", .systemBlue, value: textFor(event.start))
                    .onTapGesture {
                        withAnimation {
                            showStartDatePicker.toggle()
                            
                            if showEndDatePicker {
                                showEndDatePicker = false
                            }
                        }
                    }
                
                if showStartDatePicker {
                    DatePicker("", selection: Binding($event.start, Date()))
                        .datePickerStyle(GraphicalDatePickerStyle())
                }
                
                DetailCellDescriptor("End date", image: "calendar", .systemOrange, value: textFor(event.end))
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
                    DatePicker("", selection: Binding($event.end, Date()))
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .animation(.default)
                }
                
                HStack {
                    DetailCellDescriptor("Notification", image: "app.badge", .systemGreen, value: textForNotification())
                    Toggle("", isOn: Binding(isNotNil: $event.notificationDate, defaultValue: Date()))
                }.animation(.default)
                .onTapGesture {
                    withAnimation {
                        showNotificationDatePicker.toggle()
                    }
                }
    
                if event.notificationDate != nil && showNotificationDatePicker {
                    DatePicker("", selection: Binding($event.notificationDate)!, in: Date()...)
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .animation(.easeIn)
                }
            }
            
            //MARK: Timetable
            
            Section {
                HStack {
                    
                    NavigationLink(destination: AppTimetablePicker(timetable: $event.timetable)) {
                        DetailCellDescriptor("Timetable", image: "tray.full.fill", .systemRed, value: timetableTitle())
                        Spacer()
                        if event.timetable == TimetableService.shared.defaultTimetable() {
                            Text("Default")
                                .padding(EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10))
                                .background(Color(.tertiarySystemGroupedBackground))
                                .font(.system(size: 13, weight: .semibold))
                                .cornerRadius(10)
                        }
                    }
                    
                }
            }
            
        }.listStyle(InsetGroupedListStyle())
            
    }

    func textFor(_ date: Date?) -> String {
        return date?.stringify(dateStyle: .long, timeStyle: .short)  ?? ""
    }

    //MARK: timetableTitle
    private func timetableTitle() -> String? {
        return event.timetable?.name
    }
    
    private func textForNotification() -> String? {
        return event.notificationDate?.stringify(dateStyle: .medium, timeStyle: .short)
    }
}