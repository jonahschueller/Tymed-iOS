//
//  TimetableService.swift
//  Tymed
//
//  Created by Jonah Schueller on 02.05.20.
//  Copyright © 2020 Jonah Schueller. All rights reserved.
//

import EventKit
import Foundation
import CoreData

//MARK: Day
enum Day: Int, CaseIterable {
    
    static var current: Day {
        return Day(rawValue: Calendar.current.component(.weekday, from: Date())) ?? Day.monday
    }
    
    static func <(_ d1: Day, _ d2: Day) -> Bool {
        let v1 = d1.rawValue + (d1 == .sunday ? 7 : 0)
        let v2 = d2.rawValue + (d2 == .sunday ? 7 : 0)
        return v1 < v2
    }
    
    static func ==(_ d1: Day, _ d2: Day) -> Bool {
        return d1.rawValue == d2.rawValue
    }
    
    static func <=(_ d1: Day, _ d2: Day) -> Bool {
        return d1 < d2 || d1 == d2
    }
    
    static func from(date: Date) -> Day? {
        let comp = Calendar.current.dateComponents([.weekday], from: date)
        
        guard let weekDay = comp.weekday else {
            return nil
        }
        return Day(rawValue: weekDay)
    }
    
    /// Returns the Day from an index.
    /// Mon: 0, Tue: 1, Wed: 2, ..., Sun: 6
    static func from(index: Int) -> Day? {
        let val = index == 6 ? 1 : index + 1
        return Day(rawValue: val)
    }
    
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    
    case saturday = 7
    case sunday = 1
    
    /// Returns the rawValue as an index.
    /// Mon: 0, Tue: 1, Wed: 2, ..., Sun: 6
    var index: Int {
        return self != .sunday ? rawValue - 1 : 6
    }
    
    func date() -> Date? {
        return TimetableService.shared.dateFor(day: self)
    }
    
    func string() -> String {
        return Calendar.current.weekdaySymbols[rawValue - 1]
    }
    
    func shortString() -> String {
        return Calendar.current.shortWeekdaySymbols[rawValue - 1]
    }
    
    func rotatingNext() -> Day {
        if self == .saturday {
            return .sunday
        }
        return Day(rawValue: rawValue + 1)!
    }
    
    func isToday() -> Bool {
        return Calendar.current.component(.weekday, from: Date()) == self.rawValue
    }
    
    func nextDate() -> Date? {
//        guard let startOfWeek = Date().startOfWeek else { return nil }
        
        var comp = DateComponents()
        comp.weekday = rawValue
        
        return Calendar.current.nextDate(after: Date(), matching: comp, matchingPolicy: .strict)
    }
}

//MARK: TimetableService
class TimetableService: ObservableObject {
    
    static let shared = TimetableService()
    
    private let context = PersistanceService.shared.persistentContainer.viewContext
    
    internal init() {
        
//        let timetable = self.timetable()
//        timetable.name = "University"
//        timetable.isDefault = false
//        timetable.color = "orange"
//        
//        let event = self.event()
//        
//        event.title = "Next event"
//        event.createdAt = Date()
//        event.start = Date() + 7200
//        event.end = event.start! + 3600
//        
//        event.timetable = timetable
//        event.allDay = false
//        
//        save()
    }
    
    //MARK: - Timetable
    
    func timetable() -> Timetable {
        let timetable = Timetable(context: context)
        timetable.id = UUID()
        timetable.isDefault = false
        timetable.name = ""
        timetable.color = "red"
        
        return timetable
    }
    
    func deleteTimetable(_ timetable: Timetable) {
        
        if let tasks = timetable.tasks {
            for task in tasks {
                deleteTask(task as! Task)
            }
        }
        
        if let subjects = timetable.subjects {
            for subject in subjects {
                deleteSubject(subject as! Subject)
            }
        }
        
        context.delete(timetable)
        
        save()
    }
    
    /// Sets a new default timetable (the old default timetable will no longer be the default)
    /// - Parameter timetable: The new default timetable
    func setDefaultTimetable(_ timetable: Timetable) {
        fetchTimetables()?.forEach({ (t) in
            if t.id != timetable.id {
                t.isDefault = false
            }
        })
        save()
    }
    
    /// Returns all timetables
    func fetchTimetables() -> [Timetable]? {
        let req = NSFetchRequest<NSManagedObject>(entityName: "Timetable")
        
        do {
            let res = try context.fetch(req) as! [Timetable]
            
            return res
        }catch {
            return nil
        }
    }
    
    func defaultTimetable() -> Timetable? {
        var timetable: Timetable?
        
        fetchTimetables()?.forEach({ (t) in
            if t.isDefault {
                timetable = t
            }
        })
        
        if timetable == nil {
            timetable = fetchTimetables()?.first
        }
        
        return timetable
    }
    
    //MARK: - Events
    
    func fetchEvents() -> [Event]? {
        let req = NSFetchRequest<NSManagedObject>(entityName: "Event")
        
        do {
            
            let res = try context.fetch(req) as! [Event]
            
            return res
            
        } catch {
            return nil
        }
    }
    
    func event() -> Event {
        let event = Event(context: context)
        
        event.id = UUID()
        event.createdAt = Date()
        
        return event
    }
    
    func deleteEvent(_ event: Event) {
        context.delete(event)
        
        save()
    }
       
    func getEvents(withinDay date: Date) -> [Event] {
        let events = fetchEvents()?.filter({ event in
            guard let start = event.start, let end = event.end else {
                return false
            }
            
            let startOfDay = date.startOfDay
            let endOfDay = date.endOfDay
            
            return startOfDay <= start && start <= endOfDay || startOfDay <= end && end <= endOfDay
        })
        
        return events ?? []
    }
    
    func getEvents(within date: Date) -> [Event] {
        let events = fetchEvents()?.filter({ event in
            guard let start = event.start, let end = event.end else {
                return false
            }
            
            return start <= date && date <= end
        })
        
        return events ?? []
    }
    
    //MARK: - Subject
    func fetchSubjects() -> [Subject]? {
        let req = NSFetchRequest<NSManagedObject>(entityName: "Subject")
        
        do {
            
            let res = try context.fetch(req) as! [Subject]
            
            return res
            
        } catch {
            return nil
        }
    }
    
    func fetchSubjects(_ completion: (([Subject]?, Error?) -> Void)?) {
    
        let req = NSFetchRequest<NSManagedObject>(entityName: "Subject")
        
        do {
            
            let res = try context.fetch(req) as! [Subject]
            
            completion?(res, nil)
            
        } catch {
            completion?(nil, error)
        }
        
    }
    
    
    //MARK: Subject factory
    func subject() -> Subject {
        let subject = Subject(context: context)
        subject.id = UUID()
        
        subject.createdAt = Date()
        
        return subject
    }
    
    
    func subject(with name: String, addNewSubjectIfNull: Bool = true) -> Subject? {
        guard let subjects = fetchSubjects() else {
            if addNewSubjectIfNull {
                return addSubject(name, "blue")
            }
            return nil
        }
        
        for subject in subjects {
            if subject.name == name {
                return subject
            }
        }
        
        if addNewSubjectIfNull {
            return addSubject(name, "blue")
        }
        return nil
    }
    
    func deleteSubject(_ subject: Subject) {
        if let lessons = subject.lessons {
            for lesson in lessons {
                deleteLesson(lesson as! Lesson)
            }
        }
        
        context.delete(subject)
        
        save()
    }
    
    //MARK: addSubject(_: ...)
    func addSubject(_ name: String, _ color: String, _ createdAt: Date? = nil, _ id: UUID? = nil) -> Subject{
        
        let subject = self.subject()
        
        subject.name = name
        subject.color = color
        subject.createdAt = createdAt ?? Date()
        subject.id = id ?? UUID()
        subject.timetable = defaultTimetable()
        
        save()
        
        return subject
    }
    
    func subjectSuggestions(for title: String) -> [Subject]  {
        guard let subjects = fetchSubjects() else {
            return []
        }
        
        var values = subjects.map { (sub: Subject) in
            return (sub, sub.name.levenshteinDistanceScore(to: title))
        }
        
        values.sort(by: { (v1, v2) -> Bool in
            return v1.1 > v2.1
        })
        
        return values.map { (value: (Subject, Double)) in
            return value.0
        }
    }
    
    //MARK: - Lesson
    func fetchLessons() -> [Lesson]? {
        
        let req = NSFetchRequest<NSManagedObject>(entityName: "Lesson")
        
        do {
            
            let res = try context.fetch(req) as! [Lesson]
            
            return res
            
        } catch {
            return nil
        }
    }
    
    func fetchLessons(_ completion: (([Lesson]?, Error?) -> Void)?) {
        
        let req = NSFetchRequest<NSManagedObject>(entityName: "Lesson")
        
        do {
            
            let res = try context.fetch(req) as! [Lesson]
            
            completion?(res, nil)
            
        } catch {
            completion?(nil, error)
        }
        
    }
    
    //MARK: Lesson factory
    func lesson() -> Lesson {
        let lesson = Lesson(context: context)
        lesson.id = UUID()
        
        return lesson
    }
    
    //MARK: addLesson(...)
    func addLesson(subject: Subject, day: Day, start: Date, end: Date, note: String? = nil) -> Lesson? {
        
        let lesson = self.lesson()
        
        lesson.subject = subject
        
        lesson.dayOfWeek = Int32(day.rawValue)
        lesson.startTime = Time(from: start)
        lesson.endTime = Time(from: end)
        
        lesson.note = note
        
        save()
        
        return lesson
    }
    
    //MARK: deleteLesson(_: )
    func deleteLesson(_ lesson: Lesson) {
        context.delete(lesson)
        
        save()
    }
    
    //MARK: - Task
    /// Creates a new instance of Task and attaches an UUID
    func task() -> Task {
        let task = Task(context: context)
        task.id = UUID()
        task.unarchive()
        task.completed = false
        task.priority = 0
        
        return task
    }
    
    //MARK: addTask(...)
    func addTask(_ title: String, _ text: String = "", _ due: Date, _ lesson: Lesson? = nil, _ priority: Int = 0) -> Task? {
        let task = self.task()
        
        task.title = title
        task.completed = false
        task.text = text
        task.due = due
        task.lesson = lesson
        task.priority = Int32(priority)
        task.unarchive()
        
        save()
        
        return task
    }
    
    //MARK: save()
    func save() {
        do {
            try context.save()
            objectWillChange.send()
        } catch {
            print(error)
        }
    }
    
    //MARK: reset()
    func reset() {
        context.reset()
        objectWillChange.send()
    }
    
    func rollback() {
        context.rollback()
        objectWillChange.send()
    }
    
    func hasChanges() -> Bool {
        return context.hasChanges
    }
    
    //MARK: dateFor(day: )
    /// Creates a Date containing the given Day type as .weekday
    /// - Parameter day: Day of week
    /// - Returns: Date containing the given Day type as .weekday
    func dateFor(day: Day) -> Date? {
        var dateComponents = DateComponents()
        dateComponents.weekday = day.rawValue
        
        let cal = Calendar.current
        
        let date = DateComponents()
        
        return cal.nextDate(after: cal.date(from: date)!, matching: dateComponents, matchingPolicy: .strict)
        
    }
    
    func dateFor(hour: Int, minute: Int) -> Date {
        
        var dateComponents = DateComponents()
        
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        return Calendar.current.date(from: dateComponents)!
    }
    
    func dateFor(_ time: Time) -> Date {
        return dateFor(hour: time.hour, minute: time.minute)
    }
    
    func lessons() -> [Lesson]? {
        return fetchLessons()
    }
    
    //MARK: getLessons(date: )
    /// Fetches the lesson of the current timetable that match a given date (.weekday, .hour, .minute)
    /// - Parameter date: Date that is within the lessons
    /// - Returns: Array containing the lessons (of the current timetable) that match the date
    func getLessons(within date: Date) -> [Lesson] {
        
        do {
            let fetchRequest : NSFetchRequest<Lesson> = Lesson.fetchRequest()
            
            let weekday = Calendar.current.component(.weekday, from: date)
            
            let time = Time(from: date)
            
            fetchRequest.predicate = NSPredicate(format: "dayOfWeek == %@ AND start <= %@ AND %@ <= end", NSNumber(value: weekday), NSNumber(value: time.timeInterval), NSNumber(value: time.timeInterval))
            
            let fetchedResults = try context.fetch(fetchRequest)
                
            return fetchedResults
        }
        catch {
            print ("fetch lessons failed", error)
            return []
        }
        
    }
    
    //MARK: getLessons(time: )
    /// Fetches the lesson of the current timetable that match a given time (.hour, .minute)
    /// - Parameter time: Time that is within the lessons
    /// - Returns: Array containing the lessons (of the current timetable) that match the time
    func getLessons(within time: Time) -> [Lesson] {
        
        do {
            let fetchRequest : NSFetchRequest<Lesson> = Lesson.fetchRequest()
            
            fetchRequest.predicate = NSPredicate(format: "start <= %@ AND %@ <= end", NSNumber(value: time.timeInterval), NSNumber(value: time.timeInterval))
            
            let fetchedResults = try context.fetch(fetchRequest)
                
            return fetchedResults
        }
        catch {
            print ("fetch lessons failed", error)
            return []
        }
        
    }
    
    //MARK: getLessons(day: )
    /// Fetches the lesson of the current timetable that match a given day (.weekday)
    /// - Parameter day: Day of week of the lessons
    /// - Returns: Array containing the lessons (of the current timetable) that match the day of week
    func getLessons(within day: Day) -> [Lesson] {
        
        do {
            let fetchRequest: NSFetchRequest<Lesson> = Lesson.fetchRequest()
            
            let weekday = day.rawValue
            
            fetchRequest.predicate = NSPredicate(format: "dayOfWeek == %@", NSNumber(value: weekday))
            
            let fetchedResults = try context.fetch(fetchRequest)
                
            return fetchedResults
        }
        catch {
            print ("fetch lessons failed", error)
            return []
        }
        
    }
    
    func sortLessonsByWeekDay(_ lessons: [Lesson]) -> [Day: [Lesson]] {
        var week = [Day: [Lesson]]()
        
        lessons.forEach({ (lesson) in
            if ((week[lesson.day]) != nil) {
                week[lesson.day]?.append(lesson)
            }else {
                week[lesson.day] = [lesson]
            }
        })
        
        // Sort each day slot by time
        week.forEach { (arg0) in
            let (key, value) = arg0
            week[key] = value.sorted(by: { (l1, l2) -> Bool in
                if l1.startTime != l2.startTime {
                    return l1.startTime < l2.startTime
                }
                return l1.endTime < l2.endTime
            })
        }
        
        return week
    }
    
    
    /// Returns if the lesson is right now
    /// - Parameter lesson: Lesson to analyse
    /// - Returns: Returns if the time of the lesson is right now
    func lessonIsNow(_ lesson: Lesson) -> Bool {
        let now = Time.now
        let today = Day.current
        
        return lesson.day == today && lesson.startTime <= now && now <= lesson.endTime
    }
    
    func getNextLessons(in lessons: [Lesson]?) -> [Lesson]? {
        
        // If there aren't any lessons -> return nil
        guard var les = lessons else {
            return nil
        }
        
        let now = Time.now
        
        // Sort the lessons by day/time
        les.sort { (l1, l2) -> Bool in
            if l1.day == l2.day {
                if l1.startTime == l2.startTime {
                    return l1.endTime < l2.endTime
                }
                return l1.startTime < l2.startTime
            }
            return l1.day < l2.day
        }
        
        // Repeat as often as many items there are in the next lessons list
        for _ in 0..<les.count {
            guard let first = les.first else {
                break
            }
            // If the day is on a previous day or today but already passed or is right now
            // -> Remove form index 0 and append to the end of the list
            if  first.day < Day.current ||
                (first.day == Day.current && first.endTime < now) ||
                (lessonIsNow(first)) {
                les.remove(at: 0)
                les.append(first)
            }
        }
        
        // Reduce the lessons to the first few with the same lesson and startTime
        les = les.reduce([]) { (res, lesson) -> [Lesson] in
            if let first = res.first {
                if first.day == lesson.day && first.startTime == lesson.startTime {
                    var r = res
                    r.append(lesson)
                    return r
                }
            }else {
                return [lesson]
            }
            return res
        }
        
        return les
    }
    
    func getNextLessons() -> [Lesson]? {
        return getNextLessons(in: self.lessons())
    }
    
    //MARK: getTasks(predicate: )
    private func getTasks(_ predicate: NSPredicate) -> [Task] {

        do {
           let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
           
           fetchRequest.predicate = predicate
           
           let results = try context.fetch(fetchRequest)
           
           return results
        } catch {
           print("fetch tasks failed", error)
           return []
        }
    }
    
    func getTasks() -> [Task] {
        let req = NSFetchRequest<NSManagedObject>(entityName: "Task")
        
        do {
            
            let res = try context.fetch(req) as! [Task]
            
            return res
            
        } catch {
            return []
        }
    }
    
    /// Returns all tasks that aren't archived at the moment
    func getAllTasks() -> [Task] {
        let predicate = NSPredicate(format: "archived == false")
        return getTasks(predicate)
    }
    
    func getTasksWithCompleteState(state: Bool) -> [Task] {
        let predicate = NSPredicate(format: "completed == %@ and archived == false", NSNumber(value: state))
        return getTasks(predicate)
    }
    
    func getCompletedTasks() -> [Task] {
        let predicate = NSPredicate(format: "completed == %@ and archived == false", NSNumber(value: true))
        
        return getTasks(predicate).sorted()
    }
    
    func getExpiredTasks() -> [Task] {
        let predicate = NSPredicate(format: "due <= %@ AND completed == NO and archived == false", Date() as NSDate)
        
        return getTasks(predicate).sorted()
    }
    
    func getOpenTasks() -> [Task] {
        let predicate = NSPredicate(format: "completed == %@ and archived == false", NSNumber(value: false))
        
        return getTasks(predicate).sorted()
    }
    
    func getArchivedTasks() -> [Task] {
        let predicate = NSPredicate(format: "archived == %@", NSNumber(value: true))
        
        return getTasks(predicate).sorted()
    }
    
    func getPlannedTasks() -> [Task] {
        let predicate = NSPredicate(format: "due != nil and archived == false")
        
        return getTasks(predicate).sorted()
    }
    
    
    //MARK: getTasks(lesson: )
    func getTasks(for lesson: Lesson) -> [Task] {
        return getTasks(NSPredicate(format: "lesson == %@ and archived == false", lesson))
    }

    //MARK: getTasks(date: )
    private func getTasks(date: Date, dateOperation: String) -> [Task] {
        return getTasks(NSPredicate(format: "due \(dateOperation) %@  and archived == false", date as NSDate))
    }

    func getTasks(before date: Date) -> [Task] {
        return getTasks(date: date, dateOperation: "<=")
    }

    func getTasks(after date: Date) -> [Task] {
        return getTasks(date: date, dateOperation: ">=")
    }

    func getTasks(at date: Date) -> [Task] {
        return getTasks(date: date, dateOperation: "==")
    }
    
    func getTasks(between date1: Date, and date2: Date) -> [Task] {
        return getTasks(NSPredicate(format: "due >= %@ AND due <= %@ and archived == false", date1 as NSDate, date2 as NSDate))
    }
    
    func getNextTasks() -> [Task] {
//        let startOfToday = Calendar.current.startOfDay(for: Date())
//
//        var components = DateComponents()
//        components.day = 1
//        components.second = -1
//
//        guard let endOfToday = Calendar.current.date(byAdding: components, to: startOfToday) else { return [] }
//
        return getTasks(after: Date()).sorted()
    }
    
    //MARK: deleteTask(_: )
    func deleteTask(_ task: Task) {
        NotificationService.current.removeAllNotifications(of: task)
        
        context.delete(task)
        
        save()
    }

    //MARK: getTasksOrderedByDate(limit: )
    /// Fetches all tasks from core data sorted by their due date
    /// - Parameter limit: Max number of items starting from the first
    func getTasksOrderedByDate(limit: Int = 5) -> [Task] {
        do {
            let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
            
            let sort = NSSortDescriptor(key: #keyPath(Task.due), ascending: true)
            
            fetchRequest.sortDescriptors = [sort]
            
            fetchRequest.fetchLimit = limit
       
            let results = try context.fetch(fetchRequest)
            
            return results
            
        }catch {
            print("fetch tasks failed", error)
            return []
        }
    }
    
    
    func dateOfNext(lesson: Lesson) -> Date? {
        
        let start = lesson.startTime
        let day = lesson.day
        
        var comp = DateComponents()
        comp.weekday = day.rawValue
        comp.hour = start.hour
        comp.minute = start.minute
        
        return Calendar.current.nextDate(after: Date(), matching: comp, matchingPolicy: .strict)
    }
    
    
    
    func calendarEvents(within date: Date) -> [CalendarEvent] {
        
        var lessons = CalendarEvent.lessonEvents(lessons: getLessons(within: date))
        let events = CalendarEvent.eventEvents(events: getEvents(within: date))
        
        lessons.append(contentsOf: events)
        
        lessons.sort()
        
        return lessons
    }
    
    func calendarEventsFor(day date: Date) -> [CalendarEvent] {
        
        guard let day = Day.from(date: date) else {
            return []
        }
        
        var lessons = CalendarEvent.lessonEvents(lessons: getLessons(within: day))
        let events = CalendarEvent.eventEvents(events: getEvents(withinDay: date))
        
        lessons.append(contentsOf: events)
        
        lessons.sort()
        
        lessons.forEach { (event) in
            event.anchorDate = date.startOfDay
        }
        
        return lessons
    }
    
//    func getNextCalendarEvents(startingFrom date: Date) -> [CalendarEvent] {
//        var currentDate = date
//        for _ in 0..<7 {
//            let events = calendarEventsFor(day: currentDate)
//            
//            if events.count != 0 {
//                return events
//            }else {
//                currentDate = currentDate.nextDay
//            }
//        }
//        return []
//    }
}
