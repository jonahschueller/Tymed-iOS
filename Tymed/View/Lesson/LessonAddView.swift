//
//  LessonAddView.swift
//  Tymed
//
//  Created by Jonah Schueller on 03.08.20.
//  Copyright © 2020 Jonah Schueller. All rights reserved.
//

import SwiftUI

class LessonAddViewWrapper: ViewWrapper<LessonAddView> {
    
    override func createContent() -> UIHostingController<LessonAddView>? {
        return UIHostingController(rootView: LessonAddView(dismiss: {
            self.homeDelegate?.reload()
            self.dismiss(animated: true, completion: nil)
        }))
    }
    
}

//MARK: LessonAddView
struct LessonAddView: View {
    
    var dismiss: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    
    //MARK: Lesson Subject Title
    @State private var subjectTitle = ""
    
    //MARK: Lesson Time state
    @State private var showSubjectSuggestions = false
    
    @State private var showStartTimePicker = false
    @State private var showEndTimePicker = false
    @State private var showDayPicker = false
    
    @State private var startTime = Date()
    @State private var endTime = Date() + TimeInterval(3600)
    @State private var interval: TimeInterval = 3600
    
    @State private var day: Day = .current
    
    //MARK: Color
    @State private var color: String = "blue"
    
    //MARK: Note
    @State private var note = ""
    
    //MARK: Timetable
    @State private var timetable: Timetable?
    
    
    @State private var subjectTimetableAlert = false
    
    init(dismiss: @escaping () -> Void) {
        self.dismiss = dismiss
        _timetable = State(initialValue: TimetableService.shared.defaultTimetable())
    }
    
    init(_ defaultTimetable: Timetable, _ dismiss: @escaping () -> Void) {
        self.dismiss = dismiss
        _timetable = State(initialValue: defaultTimetable)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    if showSubjectSuggestions {
                        
                        HStack(spacing: 15) {
                            ForEach(subjectSuggestions(), id: \.self) { (subject: Subject) in
                                HStack {
                                    Spacer()
                                    Text(subject.name ?? "")
                                        .minimumScaleFactor(0.01)
                                        .lineLimit(1)
                                        .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                                    
                                    Spacer()
                                }
                                .frame(height: 30)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .background(Color(UIColor(subject) ?? .clear))
                                .cornerRadius(10.5)
                                .onTapGesture {
                                    subjectTitle = subject.name ?? ""
                                    let subject = TimetableService.shared.subject(with: subjectTitle)
                                    timetable = subject?.timetable
                                    color = subject?.color ?? "blue"
                                }
                            }
                        }.frame(height: 45)
                        .animation(.easeInOut(duration: 0.5))
                        
                    }
                    
                    CustomTextField("Subject Name", $subjectTitle) {
                        withAnimation {
                            showSubjectSuggestions.toggle()
                        }
                    } onReturn: {
                        withAnimation {
                            showSubjectSuggestions.toggle()
                        }
                    }
                    
                    NavigationLink(destination: AppColorPickerView(color: $color)) {
                        DetailCellDescriptor("Color", image: "paintbrush.fill", UIColor(named: color) ?? .clear, value: color.capitalized)
                    }
                        
                }
                
                //MARK: Times
                Section {
                    DetailCellDescriptor("Start time", image: "clock.fill", .systemBlue, value: time(for: startTime))
                        .onTapGesture {
                            withAnimation {
                                showStartTimePicker.toggle()
                                showEndTimePicker = false
                                showDayPicker = false
                            }
                        }
                    
                    if showStartTimePicker {
                        HStack {
                            Spacer()
                            DatePicker("", selection: $startTime, displayedComponents: DatePickerComponents.hourAndMinute)
                                .labelsHidden()
                                .datePickerStyle(GraphicalDatePickerStyle())
                        }.frame(height: 45)
                    }
                    
                    DetailCellDescriptor("End time", image: "clock.fill", .systemOrange, value: time(for: endTime))
                        .onTapGesture {
                            withAnimation {
                                showEndTimePicker.toggle()
                                showStartTimePicker = false
                                showDayPicker = false
                            }
                        }
                    
                    if showEndTimePicker {
                        HStack {
                            Spacer()
                            DatePicker("", selection: $endTime, in: startTime..., displayedComponents: DatePickerComponents.hourAndMinute)
                                .labelsHidden()
                                .datePickerStyle(GraphicalDatePickerStyle())
                        }.frame(height: 45)
                    }
                    
                    
                    DetailCellDescriptor("Day", image: "calendar", .systemGreen, value: day.string())
                        .onTapGesture {
                            withAnimation {
                                showDayPicker.toggle()
                                showStartTimePicker = false
                                showEndTimePicker = false
                            }
                        }
                    
                    if showDayPicker {
                        Picker("", selection: $day) {
                            ForEach(Day.allCases, id: \.self) { day in
                                Text(day.string())
                            }
                        }.pickerStyle(WheelPickerStyle())
                        .frame(height: 120)
                    }
                }
                
                
                //MARK: Calendar
                
                Section {
                    HStack {
                        
                        NavigationLink(destination: AppTimetablePicker(timetable: $timetable)) {
                            DetailCellDescriptor("Calendar", image: "tray.full.fill", .systemRed, value: timetableTitle())
                            Spacer()
                            if timetable == TimetableService.shared.defaultTimetable() {
                                Text("Default")
                                    .padding(EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10))
                                    .background(Color(.tertiarySystemGroupedBackground))
                                    .font(.system(size: 13, weight: .semibold))
                                    .cornerRadius(10)
                            }
                        }
                        
                    }
                }
                
                //MARK: Notes
                Section {
                    MultilineTextField("Notes", $note)
                }
                
            }.listStyle(InsetGroupedListStyle())
            .font(.system(size: 16, weight: .semibold))
            .navigationTitle("Lesson")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel"){
                dismiss()
                presentationMode.wrappedValue.dismiss()
            }, trailing: Button("Add") {
                addLesson()
            })
            .onChange(of: endTime) { value in
                interval = endTime.timeIntervalSince(startTime)
                print(interval)
            }
            .onChange(of: startTime) { value in
                endTime = startTime + interval
            }
            .alert(isPresented: $subjectTimetableAlert) {
                Alert(
                    title: Text("Do you want to switch timetables?"),
                    message: Text("All other lessons of the subject will change the timetables aswell."),
                    primaryButton:
                        .destructive(Text("Use \(timetable?.name ?? "")"),
                                     action: {
                                        addLesson()
                }), secondaryButton:
                        .cancel(Text("Keep \(timetableNameOfSubject())"),
                                action: {
                                    timetable = TimetableService.shared.subject(with: subjectTitle)?.timetable
                                    addLesson()
                    }))
            }
        }
    }
    
    //MARK: timetableNameOfSubject
    private func timetableNameOfSubject() -> String {
        return TimetableService.shared.subject(with: subjectTitle, addNewSubjectIfNull: false)?.timetable?.name ?? ""
    }
    
    //MARK: timetableTitle
    private func timetableTitle() -> String? {
        return timetable?.name
    }
    
    //MARK: time
    private func time(for date: Date) -> String? {
        return date.stringifyTime(with: .short)
    }
    
    //MARK: subjectSuggestions
    private func subjectSuggestions() -> [Subject] {
        return TimetableService.shared.subjectSuggestions(for: subjectTitle)
            .prefix(3)
            .map { $0 }
    }
    
    //MARK: addLesson
    private func addLesson() {
        guard let subject = TimetableService.shared.subject(with: subjectTitle) else {
            return
        }
        
        if subject.timetable != timetable {
            subjectTimetableAlert.toggle()
            return
        }
        
        subject.timetable = timetable
        subject.color = color
        
        _ = TimetableService.shared.addLesson(subject: subject, day: day, start: startTime, end: endTime, note: nil)
        
        presentationMode.wrappedValue.dismiss()
        dismiss()
    }
    
    
}


//MARK: LessonAddView_Previews
struct LessonAddView_Previews: PreviewProvider {
    static var previews: some View {
        LessonAddView {
            
        }.colorScheme(.dark)
    }
}
