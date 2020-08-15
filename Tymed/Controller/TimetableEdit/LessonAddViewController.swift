//
//  LessonAddViewController.swift
//  Tymed
//
//  Created by Jonah Schueller on 04.05.20.
//  Copyright © 2020 Jonah Schueller. All rights reserved.
//

import UIKit

private let colorSection = "colorSection"
private let timeSection = "timeSection"
private let noteSection = "noteSection"

internal let lessonNoteCell = "lessonNoteCell"

internal let lessonStartTimePickerCell = "lessonStartTimePickerCell"
internal let lessonEndTimePickerCell = "lessonEndTimePickerCell"

internal let lessonStartTimeTitleCell = "lessonStartTimeTitleCell"
internal let lessonEndTimeTitleCell = "lessonEndTimeTitleCell"
internal let lessonDayTitleCell = "lessonDayTitleCell"


internal let lessonColorPickerCell = "lessonColorPickerCell"
internal let lessonDayPickerCell = "lessonDayPickerCell"

protocol SubjectAutoFillDelegate {
    
    func subjectAutoFill(didSelect subject: String)
    
}
//MARK: SubjectAutoFill
class SubjectAutoFill: UIStackView {
    
    var subjects: [Subject]? = nil
    
    var subjectDelegate: SubjectAutoFillDelegate? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        distribution = .fillEqually
        spacing = 0
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func selectItem(_ btn: UIButton) {
        guard let title = btn.title(for: .normal) else {
            return
        }
        
        subjectDelegate?.subjectAutoFill(didSelect: title)
    }
    
    func sortSubjects(_ title: String) -> [Subject]?  {
        guard let subjects = subjects else {
            return nil
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
    
    func addSubject(_ subject: Subject) {
        let button = UIButton()
        
        button.setTitle(subject.name ?? "-", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(named: subject.color ?? "dark") ?? .blue
        
        button.addTarget(self, action: #selector(selectItem(_:)), for: .touchUpInside)
        
        addArrangedSubview(button)
    }
    
    func setupViews(_ title: String) {
        subviews.forEach { view in
            view.removeFromSuperview()
        }
        
        sortSubjects(title)?.prefix(3).forEach({ (subject) in
            self.addSubject(subject)
        })
    }
    
    func reload(_ title: String) {
        setupViews(title)
    }
}

//MARK: LessonAddViewController
class LessonAddViewController: DynamicTableViewController, UITextFieldDelegate, LessonColorPickerTableViewDelegate, UIPickerViewDelegate, LessonDayPickerCellDelegate, SubjectAutoFillDelegate {

    let textField = UITextField()
    
    var subjects: [Subject]?
    
    var autoFill: SubjectAutoFill = SubjectAutoFill()
    
    internal var expandStartTime = false {
        didSet {
            configureStartTimePicker()
        }
    }
    internal var expandEndTime = false {
        didSet {
            configureEndTimePicker()
        }
    }
    private var expandDay = false {
        didSet {
            configureDayPicker()
        }
    }
    private var invalidTimeInterval = false
    
    internal var startDate: Date = TimetableService.shared.dateFor(hour: 12, minute: 30)
    internal var endDate: Date = TimetableService.shared.dateFor(hour: 14, minute: 0)
    internal var day: Day = Day.monday
    
    private weak var startTitleCell: LessonTimeTitleCell?
    private weak var endTitleCell: LessonTimeTitleCell?
    private weak var dayTitleCell: LessonTimeTitleCell?
    
    private weak var startPickerCell: LessonTimePickerCell?
    private weak var endPickerCell: LessonTimePickerCell?
    private weak var dayPickerCell: LessonDayPickerCell?
    
    internal var noteCell: LessonAddNoteCell?
    
    // Vars for the lesson
    
    internal var lessonColor = "blue"
    
    
    // Get-only lesson params
    
    var subjectName: String? {
        textField.text
    }
    
    var lessonNote: String? {
        noteCell?.textView.text
    }

    //MARK: viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()

        // Register cell classes
        register(LessonAddNoteCell.self, identifier: lessonNoteCell)
        
        register(LessonTimeTitleCell.self, identifier: lessonStartTimeTitleCell)
        register(LessonTimeTitleCell.self, identifier: lessonEndTimeTitleCell)
        register(LessonTimeTitleCell.self, identifier: lessonDayTitleCell)
        
        register(LessonTimePickerCell.self, identifier: lessonStartTimePickerCell)
        register(LessonTimePickerCell.self, identifier: lessonEndTimePickerCell)
        
        register(LessonColorPickerCell.self, identifier: lessonColorPickerCell)
        register(LessonDayPickerCell.self, identifier: lessonDayPickerCell)
        
        subjects = TimetableService.shared.fetchSubjects()
        
        autoFill.subjects = subjects
        autoFill.reload("")
        
        // Select default color
        selectColor(lessonColor)
    }
    
    internal func fetchSubjects() {
        
    }
    
    override internal func setup() {
        super.setup()
        
        setupNavigationBar()
        
        addSection(with: timeSection)
        addSection(with: noteSection)
        addSection(with: colorSection)
        
        addCell(with: lessonColorPickerCell, at: colorSection)
        
        addCell(with: lessonStartTimeTitleCell, at: timeSection)
        addCell(with: lessonEndTimeTitleCell, at: timeSection)
        addCell(with: lessonDayTitleCell, at: timeSection)
        
        addCell(with: lessonNoteCell, at: noteSection)
        
    }
    
    //MARK: setupTextField()
    internal func setupTextField() {
        navigationController?.navigationBar.addSubview(textField)
        
        navigationItem.titleView = textField
        
        textField.delegate = self
        
        textField.autocorrectionType = .no
        
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.addTarget(self, action: #selector(titleChanged(_:)), for: .editingChanged)
        
        let toolBar = UIToolbar()
        
        toolBar.addSubview(autoFill)
        
        autoFill.subjectDelegate = self
        autoFill.backgroundColor = .red
        
        toolBar.sizeToFit()
        
        autoFill.translatesAutoresizingMaskIntoConstraints = false
        
        autoFill.leadingAnchor.constraint(equalTo: toolBar.leadingAnchor).isActive = true
        autoFill.topAnchor.constraint(equalTo: toolBar.topAnchor).isActive = true
        autoFill.widthAnchor.constraint(equalTo: toolBar.widthAnchor).isActive = true
        autoFill.heightAnchor.constraint(equalTo: toolBar.heightAnchor).isActive = true
        
        
        textField.inputAccessoryView = toolBar
        
        if let navbar = navigationController?.navigationBar {
            textField.widthAnchor.constraint(equalTo: navbar.widthAnchor, multiplier: 0.4).isActive = true
            textField.layoutIfNeeded()
        }
        
        textField.textAlignment = .center
        textField.attributedPlaceholder = NSAttributedString(string: "Subject Name", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.6) ])
        textField.textColor = .white
        
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]

    }
    
    //MARK: setupNavigationBar()
    internal func setupNavigationBar() {
        
        setupTextField()
        
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .done, target: self
            , action: #selector(add))
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self
        , action: #selector(cancel))
    }
    
    func subjectAutoFill(didSelect subject: String) {
        guard let val = subjects?.filter({ sub -> Bool in return sub.name == subject }).first else {
            return
        }
        
        textField.text = subject
        selectSubject(val)
        textField.resignFirstResponder()
    }
    
    @objc func titleChanged(_ textField: UITextField) {
        guard let subjects = self.subjects else {
            return
        }
        
        autoFill.reload(textField.text ?? "")
        
        guard let subject = subjects.filter({ subject -> Bool in return subject.name == textField.text }).first else {
            deselectSubject()
            return
        }
        
        
        selectSubject(subject)
        
    }
    
    func selectColor(_ colorName: String?) {
        if let color = UIColor(named: colorName?.lowercased() ?? "") {
            lessonColor = colorName ?? "blue"
            navigationController?.navigationBar.barTintColor = color
            navigationController?.navigationBar.tintColor = .white
            textField.textColor = .white
            tableView.reloadData()
        }
    }
    
    func selectSubject(_ subject: Subject) {
        selectColor(subject.color)
    }
    
    func deselectSubject() {
        
        
//        selectColor("blue")
    }
    
    
    
    internal func validateLesson() -> Bool {
        
        // There is no subject name
        if subjectName == nil || subjectName?.isEmpty == true {
            
            // Give feedback via taptic engine
            tapticErrorFeedback()
            
            // Highlight the textfield red for a second to show the user where the error occured
            viewTextColorErrorAnimation(for: textField, UIColor.systemRed.withAlphaComponent(0.8)) { (color) -> UIColor? in
                
                self.textField.attributedPlaceholder = NSAttributedString(string: "Subject Name", attributes: [NSAttributedString.Key.foregroundColor: color ?? .label])
                
                return UIColor.white.withAlphaComponent(0.6)
            }
            
            return false
        }
        
        // The end time is before the start time
        if invalidTimeInterval {
            
            // Give feedback via taptic engine
            tapticErrorFeedback()
            
            // Highlight the value label of the endTitleCell red for a
            // second to let the user know where the error occured
            if let label = endTitleCell?.value {
                labelErrorAnimation(label)
            }
            
            return false
        }
        
        return true
    }
    
    func createLesson() -> Lesson? {
        
        guard validateLesson() else {
            print("Lesson validation failed")
            return nil
        }
        
        print("Lesson:")
        
        print("\t\(subjectName ?? "nil")")
        print("\tColor:\(lessonColor)")
        print("\tStart: \(startDate.timeToString())")
        print("\tEnd: \(endDate.timeToString())")
        print("\tDay: \(day.date()?.dayToString() ?? "nil")")
        print("\tNote: \(lessonNote ?? "nil")")
        
        var subject: Subject? = subjects?.filter({ subject -> Bool in return subject.name == subjectName }).first
        
        if subject == nil, let name = subjectName {
            
            subject = TimetableService.shared.addSubject(name, lessonColor)
            
        }
        
        let lesson = TimetableService.shared.addLesson(subject: subject!, day: day, start: startDate, end: endDate, note: lessonNote)
        
        return lesson
    }
    
    @objc func add() {
        let lesson = createLesson()
        
        if lesson != nil {
            dismiss(animated: true, completion: nil)
        }
        
    }
    
    @objc func cancel() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Table view data source


    override func configureCell(_ cell: UITableViewCell, for identifier: String, at indexPath: IndexPath) {
        
        switch identifier {
        case lessonColorPickerCell:
            (cell as! LessonColorPickerCell).selectColor(named: lessonColor)
            break
        case lessonStartTimeTitleCell:
            let first = cell as! LessonTimeTitleCell
            startTitleCell = first
            first.title.text = "Start"
            first.value.text = startDate.timeToString()
            break
        case lessonEndTimeTitleCell:
            let cell = cell as! LessonTimeTitleCell
            endTitleCell = cell
            cell.title.text = "End"
            let attr: [NSAttributedString.Key: Any]  = invalidTimeInterval ? [NSAttributedString.Key
                                                                                .strikethroughStyle: NSUnderlineStyle.single.rawValue] : [:]
            
            cell.value.attributedText = NSAttributedString(string: endDate.timeToString(), attributes: attr)
            
            break
        case lessonDayTitleCell:
            let cell = cell as! LessonTimeTitleCell
            dayTitleCell = cell
            cell.title.text = "Day"
            cell.value.text = day.date()?.dayToString() ?? "-"
            break
        case lessonStartTimePickerCell:
            let cell = cell as! LessonTimePickerCell
            startPickerCell = cell
            cell.datePicker.setDate(startDate, animated: false)
            
            cell.datePicker.removeTarget(self, action: #selector(setEndTime(_:)), for: .valueChanged)
            
            cell.datePicker.addTarget(self, action: #selector(setStartTime(_:)), for: .valueChanged)
            break
        case lessonEndTimePickerCell:
            let cell = cell as! LessonTimePickerCell
            endPickerCell = cell
            
            cell.datePicker.setDate(endDate, animated: false)
            
            cell.datePicker.removeTarget(self, action: #selector(setStartTime(_:)), for: .valueChanged)
            
            cell.datePicker.addTarget(self, action: #selector(setEndTime(_:)), for: .valueChanged)
            
            break

        case lessonDayPickerCell:
            let cell = cell as! LessonDayPickerCell
            dayPickerCell = cell
            cell.picker.selectRow(day == Day.sunday ? 6 : day.rawValue - 2, inComponent: 0, animated: false)
            cell.lessonDelgate = self
            break
        case lessonNoteCell:
            
            let cell = cell as! LessonAddNoteCell
            noteCell = cell
        default:
            break
        }
    }

    
    @objc func setStartTime(_ datePicker: UIDatePicker) {
        startDate = datePicker.date
        
        invalidTimeInterval = endDate <= startDate
        
        tableView.reloadData()
    }
    
    @objc func setEndTime(_ datePicker: UIDatePicker) {
        endDate = datePicker.date
        
        invalidTimeInterval = endDate <= startDate
        
        tableView.reloadData()
    }
    
    func didSelectDay(_ cell: LessonDayPickerCell, day: Day) {
        self.day = day
        
        tableView.reloadData()
    }
    
    override func heightForRow(at indexPath: IndexPath, with identifier: String) -> CGFloat {
        
        switch identifier {
        case lessonColorPickerCell, lessonStartTimeTitleCell, lessonEndTimeTitleCell, lessonDayTitleCell:
            return 50
        case lessonStartTimePickerCell, lessonEndTimePickerCell, lessonDayPickerCell:
            return 150
        case lessonNoteCell:
            return 120
        default:
            return 50
        }
        
    }
    
    override func headerForSection(with identifier: String, at index: Int) -> String? {
        switch identifier {
        case colorSection:
            return "Color"
        case timeSection:
            return "Time"
        case noteSection:
            return "Notes"
        default:
            return nil
        }
    }
    
    override func iconForSection(with identifier: String, at index: Int) -> String? {
        switch identifier {
        case colorSection:
            return "paintbrush.fill"
        case timeSection:
            return "clock.fill"
        case noteSection:
            return "paperclip"
        default:
            return nil
        }
    }
    
    private func configurePickerCell(_ expand: Bool, _ titleId: String, pickerId: String, sectionId: String) {
        guard let titleIndex = identifier(for: titleId, at: sectionId) else {
            return
        }
        if expand {
            insertCell(with: pickerId, in: sectionId, at: titleIndex + 1)
        } else if let pickerIndex = identifier(for: pickerId, at: sectionId) {
            removeCell(at: sectionId, row: pickerId)
            if let secId = self.sectionIndex(for: sectionId), tableView.cellForRow(at: IndexPath(row: pickerIndex
                                                                                                    + 1, section: secId)) != nil {
                tableView.reloadRows(at: [IndexPath(row: pickerIndex + 1, section: secId)], with: tableViewUpdateAnimation)
            }
        }
    }
    
    private func configureStartTimePicker() {
        configurePickerCell(expandStartTime, lessonStartTimeTitleCell, pickerId: lessonStartTimePickerCell, sectionId: timeSection)
    }
    
    private func configureEndTimePicker() {
        configurePickerCell(expandEndTime, lessonEndTimeTitleCell, pickerId: lessonEndTimePickerCell, sectionId: timeSection)
    }
    
    private func configureDayPicker() {
        configurePickerCell(expandDay, lessonDayTitleCell, pickerId: lessonDayPickerCell, sectionId: timeSection)
    }
    
    override func didSelectRow(at indexPath: IndexPath, with identifier: String) {
        
        switch identifier {
        case lessonColorPickerCell:
            let detail = LessonColorPickerTableView(style: .insetGrouped)
            detail.lessonDelegate = self
            detail.selectedColor = lessonColor
            navigationController?.pushViewController(detail, animated: true)
            break
        case lessonStartTimeTitleCell:
            tableViewUpdateAnimation = .fade
            expandStartTime.toggle()
            expandEndTime = false
            expandDay = false
            
            break
        case lessonEndTimeTitleCell:
            tableViewUpdateAnimation = .fade
            expandEndTime.toggle()
            expandStartTime = false
            expandDay = false

            break
        case lessonDayTitleCell:
            tableViewUpdateAnimation = .fade
            expandDay.toggle()
            expandStartTime = false
            expandEndTime = false
            
            break

        default:
            break
        }
        
        
    }
 
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    func colorPicker(didSelect color: String) {
        selectColor(color)
        tableView.reloadData()
        navigationController?.popViewController(animated: true)
    }
    
}

//MARK: - LessonAddNoteCell
class LessonAddNoteCell: UITableViewCell {
    
    let textView = UITextView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(textView)
        
        textView.backgroundColor = .clear
        
        textView.font = UIFont.systemFont(ofSize: 16)
        
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        textView.constraintTopToSuperview()
        textView.constraintHeightToSuperview()
        
        textView.constraintLeadingToSuperview(constant: 20)
        textView.constraintTrailingToSuperview(constant: 20)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}

//MARK: - LessonTimeTitleCell
class LessonTimeTitleCell: UITableViewCell {
    
    let title = UILabel()

    let value = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(title)
        contentView.addSubview(value)
        
        title.text = "Start"
        value.text = "12:30"
        
        title.translatesAutoresizingMaskIntoConstraints = false
        
        
        title.constraintLeadingToSuperview(constant: 20)
        title.constraintCenterYToSuperview()
        
        title.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.4).isActive = true
        title.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.9).isActive = true
        
        value.translatesAutoresizingMaskIntoConstraints = false
        
        value.constraintTrailingToSuperview(constant: 20)
        value.constraintCenterYToSuperview()
        
        value.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5).isActive = true
        value.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.9).isActive = true
        
        value.textAlignment = .right
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}

//MARK: - LessonTimePickerCell
class LessonTimePickerCell: UITableViewCell {
    
    let datePicker = UIDatePicker()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(datePicker)
        
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 14, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        datePicker.datePickerMode = .time
        
        datePicker.constraintToSuperview(top: 0, bottom: 0, leading: 20, trailing: 20)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}

protocol LessonDayPickerCellDelegate {
    func didSelectDay(_ cell: LessonDayPickerCell, day: Day)
}

//MARK: - LessonDayPickerCell
class LessonDayPickerCell: UITableViewCell, UIPickerViewDelegate, UIPickerViewDataSource {
    
    let days: [Day] = [
        Day.monday,
        Day.tuesday,
        Day.wednesday,
        Day.thursday,
        Day.friday,
        Day.saturday,
        Day.sunday
    ]
    
    let picker = UIPickerView()
    
    var lessonDelgate: LessonDayPickerCellDelegate?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(picker)
        
        picker.delegate = self
        picker.dataSource = self
        
        picker.translatesAutoresizingMaskIntoConstraints = false
        
        picker.constraintToSuperview(top: 0, bottom: 0, leading: 20, trailing: 20)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return days.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return days[row].date()?.dayToString()
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        lessonDelgate?.didSelectDay(self, day: days[row])
    }
    
}

//MARK: - LessonColorPickerCell
class LessonColorPickerCell: UITableViewCell {
    
    let label = UILabel()
    
    let colorIndicator = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        
        accessoryType = .disclosureIndicator
        
        addSubview(colorIndicator)
        
        colorIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        colorIndicator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20).isActive = true
        colorIndicator.widthAnchor.constraint(equalToConstant: 10).isActive = true
        
        colorIndicator.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        colorIndicator.heightAnchor.constraint(equalToConstant: 10).isActive = true
        
        addSubview(label)

        label.translatesAutoresizingMaskIntoConstraints = false
        
        label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        label.leadingAnchor.constraint(equalTo: colorIndicator.trailingAnchor, constant: 10).isActive = true
        
        label.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.7).isActive = true
        label.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.9).isActive = true
        
        colorIndicator.layer.cornerRadius = 5
        
        selectColor(named: "orange")
    }
    
    func selectColor(named: String) {
        
        guard let color = UIColor(named: named.lowercased()) else {
            return
        }
        
        label.text = named.capitalized
        colorIndicator.backgroundColor = color
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

protocol LessonColorPickerTableViewDelegate {
    
    func colorPicker(didSelect color: String)
    
}

private let lessonColorIndicationCell = "lessonColorIndicationCell"
//MARK: - LessonColorPickerTableView
class LessonColorPickerTableView: UITableViewController {
    
    private var colors = ["blue", "orange", "red", "green", "dark"]
    
    var selectedColor: String = "orange"
    
    var lessonDelegate: LessonColorPickerTableViewDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Subject color"
        
        tableView.register(LessonColorIndicationCell.self, forCellReuseIdentifier: lessonColorIndicationCell)
        
        tableView.contentInset = UIEdgeInsets(top: 25, left: 0, bottom: 25, right: 0)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return colors.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: lessonColorIndicationCell, for: indexPath) as! LessonColorIndicationCell
        
        cell.isSelected = selectedColor.lowercased() == colors[indexPath.row]
        
        cell.setColor(named: colors[indexPath.row])
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? LessonColorIndicationCell else {
            return
        }
        
        selectedColor = cell.label.text ?? "blue"
        lessonDelegate?.colorPicker(didSelect: cell.label.text?.lowercased() ?? "blue")
        
        tableView.reloadData()
    }
}

//MARK: - LessonColorIndicationCell
class LessonColorIndicationCell: UITableViewCell {
    
    let label = UILabel()
    
    let colorIndicator = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
    
    override var isSelected: Bool {
        didSet {
            accessoryType = isSelected ? .checkmark : .none
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        
        addSubview(colorIndicator)
        
        colorIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        colorIndicator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20).isActive = true
        colorIndicator.widthAnchor.constraint(equalToConstant: 10).isActive = true
        
        colorIndicator.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        colorIndicator.heightAnchor.constraint(equalToConstant: 10).isActive = true
        
        addSubview(label)

        label.translatesAutoresizingMaskIntoConstraints = false
        
        label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        label.leadingAnchor.constraint(equalTo: colorIndicator.trailingAnchor, constant: 10).isActive = true
        
        label.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.7).isActive = true
        label.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.9).isActive = true
        
        colorIndicator.layer.cornerRadius = 5
        
        setColor(named: "orange")
    }
    
    func setColor(named: String) {
        
        guard let color = UIColor(named: named.lowercased()) else {
            return
        }
        
        label.text = named.capitalized
        colorIndicator.backgroundColor = color
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
