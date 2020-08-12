//
//  TaskAddView.swift
//  Tymed
//
//  Created by Jonah Schueller on 02.08.20.
//  Copyright © 2020 Jonah Schueller. All rights reserved.
//

import SwiftUI
import CoreData

class TaskAddViewWrapper: UIViewController {
    
    var taskDelegate: HomeTaskDetailDelegate?
    
    lazy var contentView = UIHostingController(rootView: TaskAddView(dismiss: {
        self.taskDelegate?.reload()
        self.dismiss(animated: true, completion: nil)
    }))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChild(contentView)
        view.addSubview(contentView.view)
        
        setupConstraints()
    }
    
    fileprivate func setupConstraints() {
        contentView.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.view.constraintToSuperview()
    }
}

//MARK: TaskAddView
struct TaskAddView: View {
    
    var dismiss: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    
    //MARK: Title states
    @State
    private var taskTitle = ""
    
    @State
    private var taskDescription = ""
    
    
    //MARK: Due date state
    @State
    private var hasDueDate = true
    
    @State
    private var presentDueDatePicker = false
    
    @State
    private var dueDate: Date?
    
    @State
    private var pickerDate = Date()
    
    @State
    private var recommendedDueDate = false
    
    @State
    private var sendNotification = false
    
    @State
    private var presentNotificationPicker = false
    
    @State
    var notificationOffset: NotificationOffset = NotificationOffset.atEvent
    
    //MARK: Lesson state
    @State
    private var hasLessonAttached = false
    
    @State
    private var presentLessonPicker = false
    
    @State
    private var lesson: Lesson?
    
    var body: some View {
        NavigationView {
            List {
                
                //MARK: Title
                Section {
                    TextField("Title", text: $taskTitle)
                    TextField("Description", text: $taskDescription).lineLimit(-1)
                }
                
                //MARK: Due Date
                Section {
                    if recommendedDueDate && lesson != nil {
                        
                        HStack {
                            DetailCellDescriptor("Recommended due date",
                                                 image: "star.fill",
                                                 .systemYellow,
                                                 value: lesson!.nextStartDate()?.stringify(dateStyle: .short, timeStyle: .short))
                                .onTapGesture {
                                    withAnimation {
                                        dueDate = lesson!.nextStartDate()
                                        recommendedDueDate = false
                                    }
                                }.font(.system(size: 13, weight: .semibold))
                        }
                        
                    }
                    
                    HStack {
                        
                        DetailCellDescriptor("Due date", image: "calendar", .systemRed, value: hasDueDate ? pickerDate.stringify(dateStyle: .short, timeStyle: .short) : nil)
                        .onTapGesture {
                            withAnimation {
                                presentDueDatePicker.toggle()
                            }
                        }
                        
                        Toggle("", isOn: $hasDueDate).labelsHidden()
                    }.frame(height: 45)
                    
                    
                    if hasDueDate {
                        if presentDueDatePicker {
                            DatePicker("", selection: $pickerDate)
                                .datePickerStyle(GraphicalDatePickerStyle())
                                .frame(height: 350)
                        }
                        
                        //MARK: Notification
                        HStack {
                            DetailCellDescriptor("Notification", image: "alarm.fill", .systemGreen, value: textForNotificationCell())
                            .onTapGesture {
                                withAnimation {
                                    presentNotificationPicker.toggle()
                                }
                            }
                            
                            Toggle("", isOn: $sendNotification).labelsHidden()
                        }.frame(height: 45)
                        
                        
                        if sendNotification && presentNotificationPicker {
                            NavigationLink(
                                destination: NotificationOffsetView(notificationOffset: $notificationOffset),
                                label: {
                                    HStack {
                                        Spacer()
                                        Text(notificationOffset.title)
                                    }
                                }).frame(height: 45)
                        }
                    }
                    
                }
                
                //MARK: Lesson Attach
                Section {
                    
                    HStack {
                        DetailCellDescriptor("Lesson", image: "doc.text.fill", .systemBlue)
                        
                        Toggle("", isOn: $hasLessonAttached)
                    }.frame(height: 45)
                    
                    
                    if hasLessonAttached {
                        NavigationLink(
                            destination: LessonPickerView(lesson: $lesson),
                            label: {
                                HStack {
                                    if lesson != nil {
                                        Circle()
                                            .frame(width: 10, height: 10)
                                            .foregroundColor(subjectColor(lesson))
                                    }
                                    
                                    Text(titleForLessonCell())
                                        .foregroundColor(foregroundColorForLessonCell())
                                    Spacer()
                                    if lesson != nil {
                                        Text(lessonTime(lesson))
                                    }
                                        
                                }.contentShape(Rectangle())
                                .frame(height: 45)
                                .font(.system(size: 14, weight: .semibold))
                            }).frame(height: 45)
                    }
                }
            }.listStyle(InsetGroupedListStyle())
            .font(.system(size: 16, weight: .semibold))
            .navigationTitle("Task")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel", action: {
                cancel()
            }), trailing: Button("Add", action: {
                addTask()
            }))
            .onChange(of: pickerDate) { value in
                dueDate = pickerDate
            }.onChange(of: hasDueDate) { value in
                dueDate = value ? dueDate : nil
            }.onChange(of: lesson) { value in
                recommendedDueDate = lesson != nil
            }
        }
    }
    
    private func titleForLessonCell() -> String {
        return lesson?.subject?.name ?? "Choose a lesson"
    }
    
    private func textForLessonDate() -> String {
        guard let lesson = self.lesson else {
            return ""
        }
        
        return "\(lesson.day.shortString()) \u{2022} \(lesson.startTime.string() ?? "") - \(lesson.endTime.string() ?? "")"
    }
    
    private func foregroundColorForLessonCell() -> Color {
        return lesson?.subject?.name != nil ? Color(.label) : Color(.systemBlue)
    }
    
    private func textForNotificationCell() -> String {
        guard let date = dueDate, sendNotification else { return "" }
        
        return (date - notificationOffset.timeInterval).stringify(dateStyle: .short, timeStyle: .short)
    }
    
    private func subjectColor(_ lesson: Lesson?) -> Color {
        return Color(UIColor(lesson) ?? .clear)
    }
    
    private func lessonTime(_ lesson: Lesson?) -> String {
        return "\(lesson?.startTime.string() ?? "") - \(lesson?.endTime.string() ?? "")"
    }
    
    private func cancel() {
        dismiss()
        presentationMode.wrappedValue.dismiss()
    }
    
    private func addTask() {
        let task = TimetableService.shared.task()
        
        task.title = taskTitle
        task.text = taskDescription
        task.due = hasDueDate ? dueDate : nil
        task.lesson = hasLessonAttached ? lesson : nil
        task.completed = false
        task.priority = 0
        task.archived = false
        
        guard let defaultTimetable = TimetableService.shared.defaultTimetable() else {
            return
        }
        task.timetable = defaultTimetable
        
        TimetableService.shared.save()
        
        if sendNotification {
            NotificationService.current.scheduleDueDateNotification(for: task, notificationOffset)
        }
        
        dismiss()
        presentationMode.wrappedValue.dismiss()
    }
}


struct TaskAddView_Previews: PreviewProvider {
    static var previews: some View {
        TaskAddView(dismiss: {
            
        }).colorScheme(.dark)
    }
}
