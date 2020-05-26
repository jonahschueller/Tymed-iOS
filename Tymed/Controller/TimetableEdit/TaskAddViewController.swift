//
//  TaskAddViewController.swift
//  Tymed
//
//  Created by Jonah Schueller on 22.05.20.
//  Copyright © 2020 Jonah Schueller. All rights reserved.
//

import UIKit

private let taskTitleCell = "taskTitleCell"
private let taskDescriptionCell = "taskDescriptionCell"
private let taskDueDateTitleCell = "taskDueDateTitleCell"
private let taskDueDateCell = "taskDueDateCell"
private let taskAttachLessonCell = "taskAttchLessonCell"
private let taskAttachedLessonCell = "taskAttachedLessonCell"

//MARK: TaskAddViewController
class TaskAddViewController: TymedTableViewController, TaskLessonPickerDelegate {

    private var expandDueDateCell = false
    
    private var lesson: Lesson?
    
    private var dueDate = Date()
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func setup() {
        super.setup()
        
        setupNavigationBar()
        
        
    }

    internal func setupNavigationBar() {
        
        title = "Task"
        navigationController?.navigationBar.prefersLargeTitles = false
        
        let rightItem = UIBarButtonItem(title: "Add", style: .done, target: self, action: #selector(addTask))
        
        navigationItem.rightBarButtonItem = rightItem
        
        let leftItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancel))
        
        navigationItem.leftBarButtonItem = leftItem
        
        register(UINib(nibName: "TaskTitleTableViewCell", bundle: nil), identifier: taskTitleCell)
        register(UINib(nibName: "TaskDescriptionTableViewCell", bundle: nil), identifier: taskDescriptionCell)
        register(UINib(nibName: "TaskDueDateTableViewCell", bundle: nil), identifier: taskDueDateCell)
        register(UINib(nibName: "TaskDueDateTitleTableViewCell", bundle: nil), identifier: taskDueDateTitleCell)
        register(UINib(nibName: "TaskLessonAttachTableViewCell", bundle: nil), identifier: taskAttachLessonCell)
        register(TaskAttachedLessonTableViewCell.self, identifier: taskAttachedLessonCell)
        
        addSection(with: "task")
        addCell(with: taskTitleCell, at: "task")
        
        addSection(with: "description")
        addCell(with: taskDescriptionCell, at: "description")
        
        addSection(with: "lesson")
        addCell(with: taskAttachLessonCell, at: "lesson")
        
        addSection(with: "due")
        addCell(with: taskDueDateTitleCell, at: "due")
    }

    @objc func addTask() {
        let task = TimetableService.shared.task()
        
        task.completed = false
        task.due = dueDate
        task.lesson = lesson
        task.priority = 0
        task.title = "My task"
        task.text = "My text"
        
        dismiss(animated: true, completion: nil)
    }
    
    @objc func cancel() {
        dismiss(animated: true, completion: nil)
    }

    override func headerForSection(with identifier: String, at index: Int) -> String? {
        switch index {
        case 0:
            return ""
        case 1:
            return "Description"
        case 2:
            return "Lesson"
        case 3:
            return "Due date"
        default:
            return ""
        }
    }

    @objc func removeLesson() {
        
        lesson = nil
        removeCell(at: 2, row: 0)
        addSection(with: "lesson", at: 2)
        tableView.deleteRows(at: [IndexPath(row: 0, section: 2)], with: .fade)
        addCell(with: taskAttachLessonCell, at: "lesson")
        tableView.insertRows(at: [IndexPath(row: 0, section: 2)], with: .fade)
    }
    
    override func configureCell(_ cell: UITableViewCell, for identifier: String, at indexPath: IndexPath) {
        
        if identifier == taskAttachLessonCell {
            let cell = cell as! TaskLessonAttachTableViewCell
            cell.attchLesson.addTarget(self, action: #selector(showLessonPicker), for: .touchUpInside)
        } else if identifier == taskAttachedLessonCell {
            let cell = cell as! TaskAttachedLessonTableViewCell
            
            cell.removeBtn.addTarget(self, action: #selector(removeLesson), for: .touchUpInside)
            
            cell.setLesson(lesson)
        } else if identifier == taskDueDateTitleCell {
            let cell = cell as! TaskDueDateTitleTableViewCell
            
            cell.titleLabel.text = "Due"
            cell.valueLabel.text = dueDate.stringify(dateStyle: .short, timeStyle: .short)
        } else if identifier == taskDueDateCell {
            let cell = cell as! TaskDueDateTableViewCell
            
            cell.dueDate.date = dueDate
        }
        
    }
    
    override func heightForRow(at indexPath: IndexPath, with identifier: String) -> CGFloat {
        switch identifier {
        case taskTitleCell:
            return 40
        case taskDueDateTitleCell, taskAttachedLessonCell, taskAttachLessonCell:
            return 50
        case taskDescriptionCell:
            return 120
        case taskDueDateCell:
            return 160
        default:
            return 0
        }
    }
    
    override func didSelectRow(at indexPath: IndexPath, with identifier: String) {
        super.didSelectRow(at: indexPath, with: identifier)
        
        let section = indexPath.section
        let row = indexPath.row
        let sectionIdentifer = sectionIdentifier(for: section)
        
        switch sectionIdentifer {
        case "due":
            if row == 0 {
                
                if expandDueDateCell {
                    removeCell(at: section, row: 1)
                    tableView.deleteRows(at: [IndexPath(row: 1, section: section)], with: .top)
                }else {
                    addCell(with: taskDueDateCell, at: "due")
                    tableView.insertRows(at: [IndexPath(row: 1, section: section)], with: .top)
                }
                expandDueDateCell.toggle()

            }
        case "lesson":
            showLessonPicker()
        default:
            break
        }
    }
    
    @objc func showLessonPicker() {
        let lessonPicker = TaskLessonPickerTableViewController(style: .insetGrouped)
        lessonPicker.lessonDelegate = self
        
        present(UINavigationController(rootViewController: lessonPicker), animated: true, completion: nil)
    }
    
    func taskLessonPicker(_ picker: TaskLessonPickerTableViewController, didSelect lesson: Lesson) {
        
        if self.lesson == nil {
            removeCell(at: 2, row: 0)
            addSection(with: "lesson", at: 2)
            addCell(with: taskAttachedLessonCell, at: "lesson")
            
            if let date = TimetableService.shared.dateOfNext(lesson: lesson) {
                dueDate = date
            }
        }
            
        self.lesson = lesson
        
        tableView.reloadData()
    }
    
    func taskLessonPickerDidCancel(_ picker: TaskLessonPickerTableViewController) {
        
    }
}

protocol TaskLessonPickerDelegate {
    
    func taskLessonPicker(_ picker: TaskLessonPickerTableViewController, didSelect lesson: Lesson)
    
    func taskLessonPickerDidCancel(_ picker: TaskLessonPickerTableViewController)
    
}

//MARK: TaskLessonPickerTableViewController
class TaskLessonPickerTableViewController: UITableViewController {
        
    private var lessons: [Lesson]?
    private var displayedLessons: [Lesson]?
    
    private var weekDays: [Day]?
    private var week: [Day: [Lesson]]?
    
    var lessonDelegate: TaskLessonPickerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lessons = TimetableService.shared.fetchLessons()
        displayedLessons = lessons
        
        tableView.register(TaskLessonPickerTableViewCell.self, forCellReuseIdentifier: "lessonCell")
        
        let cancelItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancel))
        navigationItem.leftBarButtonItem = cancelItem
        
        title = "Lesson"
        
        reload()
    }
    
    @objc func cancel() {
        lessonDelegate?.taskLessonPickerDidCancel(self)
        dismiss(animated: true, completion: nil)
    }
    
    func reload() {
        guard let lessons = displayedLessons else {
            return
        }
        
        week = TimetableService.shared.sortLessonsByWeekDay(lessons)
        
        guard let week = self.week else {
            return
        }
        
        weekDays = Array(week.keys).sorted(by: { $0 < $1})
        
        tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return weekDays?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let day = weekDays?[section] else {
            return 0
        }
        return week?[day]?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "lessonCell", for: indexPath) as! TaskLessonPickerTableViewCell
        
        guard let day = weekDays?[indexPath.section] else {
            return cell
        }
        
        cell.setLesson(week?[day]?[indexPath.row])
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return weekDays?[section].string() ?? ""
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath) as! TaskLessonPickerTableViewCell
        
        guard let lesson = cell.lesson else {
            return
        }
        
        lessonDelegate?.taskLessonPicker(self, didSelect: lesson)
        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
}

//MARK: TaskLessonPickerTableViewCell
class TaskLessonPickerTableViewCell: UITableViewCell {
    
    var colorIndicator = UIView()
    
    var name = PaddingLabel()
    
    var time = UILabel()
    
    var lesson: Lesson?
    
    internal var tasksImage: UIImageView!
    var tasksLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupUserInterface()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal func setupUserInterface() {
        
        //MARK: colorIndicator
        addSubview(colorIndicator)
        
        colorIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        colorIndicator.backgroundColor = .label
        
        colorIndicator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20).isActive = true
        colorIndicator.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        colorIndicator.heightAnchor.constraint(equalToConstant: 10).isActive = true
        colorIndicator.widthAnchor.constraint(equalToConstant: 10).isActive = true
        
        colorIndicator.layer.cornerRadius = 5
        
        //MARK: name
        addSubview(name)
        
        name.translatesAutoresizingMaskIntoConstraints = false
        
        name.leadingAnchor.constraint(equalTo: colorIndicator.trailingAnchor, constant: 15).isActive = true
        name.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        name.heightAnchor.constraint(greaterThanOrEqualToConstant: 0).isActive = true
        name.widthAnchor.constraint(greaterThanOrEqualToConstant: 0).isActive = true
        
        name.textColor = UIColor.label
        name.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        
        //MARK: time
        addSubview(time)
        
        time.translatesAutoresizingMaskIntoConstraints = false
        
        time.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15).isActive = true
        time.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        time.leadingAnchor.constraint(equalTo: centerXAnchor).isActive = true
        time.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        time.textAlignment = .right
        
        time.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        time.textColor = .label
    }
    
    func setLesson(_ lesson: Lesson?) {
        guard let lesson = lesson else {
            return
        }
        
        self.lesson = lesson
        
        name.text = lesson.subject?.name
        
        name.sizeToFit()
        
        time.text = "\(lesson.startTime.string() ?? "") \u{2022} \(lesson.endTime.string() ?? "")"
        
        let color: UIColor? = UIColor(named: lesson.subject?.color ?? "dark") ?? UIColor(named: "dark")

        colorIndicator.backgroundColor = color
    }
    
}


