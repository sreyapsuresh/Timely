import SwiftUI

struct ContentView: View {
    @State private var tasks: [Task] = []
    @State private var selectedCategory: Category? = nil
    @State private var showingAddTaskView = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Category.allCases, id: \.self) { category in
                    ForEach(sortedTasks(for: category), id: \.id) { task in // I need to adjust this if I want to make the priority
                                                                            // functionality actually work
                        
                        let isDueSoon = isTaskDueSoon(task)
                        let isDueToday = isTaskDueToday(task)
                        
                        NavigationLink(destination: TaskDetail(tasks: $tasks, task: task)) {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(priorityIndicator(for: task) + task.name) // If important, ⭐️ appears next to the task name
                                        .font(.headline)
                                    Spacer()
                                }
                                Text("\(task.category.rawValue)") // Category
                                    .font(.caption)
                                    .padding(5)
                                    .background(categoryColor(category).opacity(0.2)) // Assigns color through helper function
                                    .cornerRadius(50)
                                if let dueDate = task.dueDate {
                                    Text("\(dueDateFormatted(dueDate))") // Due date
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                        .padding(5)
                                        .background(
                                            isDueToday ? Color.red.opacity(0.2) : (isDueSoon ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.2)) // Conditional color!!!
                                        )
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("My To-do List")
            .navigationBarItems(trailing:
                Button(action: {
                    showingAddTaskView = true
                }) {
                    Image(systemName: "plus")
                }
            )
            .sheet(isPresented: $showingAddTaskView) { // Not a whole new screen, just a display over
                AddTaskView(isPresented: $showingAddTaskView, tasks: $tasks)
            }
        }
    }
    
    private func sortedTasks(for category: Category) -> [Task] { // Scuffed sorting...
        return tasks.filter { $0.category == category } // I need to change this if I want prioritization to work across categories
            .sorted { task1, task2 in
                // Prioritize important tasks over non-important tasks within each category
                if task1.isImportant && !task2.isImportant {
                    return true
                } else if !task1.isImportant && task2.isImportant {
                    return false
                } else {
                    // If both tasks are important or both are non-important, sort by due date
                    if let dueDate1 = task1.dueDate, let dueDate2 = task2.dueDate {
                        return dueDate1 < dueDate2
                    }
                    return false
                }
            }
    }
    
    private func isTaskDueToday(_ task: Task) -> Bool { // Checks if the task is due TODAY (as per system clock)
        guard let dueDate = task.dueDate else { return false }
        let calendar = Calendar.current
        let currentDate = calendar.startOfDay(for: Date())
        let taskDueDate = calendar.startOfDay(for: dueDate)
        
        return calendar.isDate(currentDate, inSameDayAs: taskDueDate)
    }
    
    private func isTaskDueSoon(_ task: Task) -> Bool { // Checks if the task is due within the week (as per system clock)
        guard let dueDate = task.dueDate else { return false }
        let currentDate = Date()
        let oneWeekFromNow = Calendar.current.date(byAdding: .day, value: 7, to: currentDate) ?? Date()
        
        return currentDate < dueDate && dueDate <= oneWeekFromNow
    }
    
    private func dueDateFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none // No time
        
        return formatter.string(from: date)
    }
    
    private func categoryColor(_ category: Category) -> Color { // I'd like to make this fall into a theme in the future
        switch category {
        case .personal:
            return Color.green
        case .school:
            return Color.blue
        case .work:
            return Color.purple
        }
    }
    
    private func priorityIndicator(for task: Task) -> String { // Add a ⭐️! I'd like to make a similr feature for tasks due soon too...
        return task.isImportant ? "⭐️ " : ""
    }
    
    struct TaskDetail: View {
        @Binding var tasks: [Task]
        let task: Task
        @State private var isDone = false
        
        var body: some View {
            VStack {
                Text("\(task.category.rawValue)")
                    .font(.title)
                Text(Task.priorityIndicator(task) + task.name)
                    .font(.largeTitle.bold())
                if let dueDate = task.dueDate {
                    Text("\(Task.dueDateFormatted(dueDate))")
                        .font(.headline)
                }
                Button(action: {
                    isDone.toggle()
                    if isDone {
                        // Remove the task from the list when marked as done
                        tasks.removeAll { $0.id == task.id }
                    }
                }) {
                    Text("Mark as Complete")
                }
                .foregroundColor(.green)
                .padding()
            }
        }
    }
    
    struct AddTaskView: View {
        @Binding var isPresented: Bool
        @Binding var tasks: [Task]
        @State private var taskName = ""
        @State private var selectedCategory: Category = .personal
        @State private var dueDate = Date() // Default due date
        @State private var isImportant = false // Flag for marking task as important
        
        var body: some View {
            NavigationView {
                Form {
                    Section(header: Text("New Task")) {
                        TextField("Task Name", text: $taskName)
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(Category.allCases, id: \.self) { category in
                                Text(category.rawValue)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        // Can't pick a date in the past
                        DatePicker("Due Date", selection: $dueDate, in: Date()..., displayedComponents: [.date])
                        
                        Toggle("Mark as Important", isOn: $isImportant)
                    }
                    
                    Button(action: {
                        // Add the new task
                        if !taskName.isEmpty {
                            let newTask = Task(id: UUID(), name: taskName, category: selectedCategory, dueDate: dueDate, isImportant: isImportant)
                            tasks.append(newTask)
                            isPresented = false // Dismiss AddTaskView
                        }
                    }) {
                        Text("Add Task")
                    }
                }
                .navigationTitle("Add New Task")
            }
        }
    }
    
    struct Task: Identifiable {
        var id: UUID
        let name: String
        let category: Category
        var dueDate: Date? // Optional due date
        var isImportant: Bool // Shows if task is important or not
        
        static func dueDateFormatted(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none // No time
            return formatter.string(from: date)
        }
        
        static func priorityIndicator(_ task: Task) -> String {
            return task.isImportant ? "⭐️ " : ""
        }
    }
    
    enum Category: String, CaseIterable {
        case personal = "Personal"
        case school = "School"
        case work = "Work"
    }
    
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }
}
