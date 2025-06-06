import 'package:flutter/material.dart';

void main() {
  runApp(const ToDoApp());
}

class ToDoApp extends StatelessWidget {
  const ToDoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const TodoApp(),
      debugShowCheckedModeBanner: false,
      // removing the debug banner
    );
  }
}

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  final List<ToDoItem> _task = [];
  final TextEditingController _taskController = TextEditingController();

  void _addTask(String title) {
    if (title.isEmpty) return;
    setState(() {
      _task.add(ToDoItem(title: title));
      _taskController.clear();
    });
  }

  void _deletetask(int index) {
    setState(() {
      _task.removeAt(index);
    });
  }

  void toggleTask(int index) {
    setState(() {
      _task[index].isDone = !_task[index].isDone;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: IconButton(
              icon: const Icon(Icons.delete_forever),
              iconSize: 30.0,
              tooltip: 'Delete All Tasks',
              onPressed: () {
                setState(() {
                  _task.clear();
                });
              },
            ),
          ),
        ],
      ),
      body: _task.isEmpty
          ? const Center(child: Text('No tasks yet!'))
          : ListView.builder(
              itemCount: _task.length,
              itemBuilder: (context, index) {
                final task = _task[index];
                return Dismissible(
                  key: Key(task.title + index.toString()),
                  background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(left: 20),
                      child: const Icon(Icons.delete, color: Colors.white)),
                  direction: DismissDirection.startToEnd,
                  onDismissed: (_) => _deletetask(index),
                  child: ListTile(
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration:
                              task.isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      leading: Checkbox(
                        value: task.isDone,
                        onChanged: (value) {
                          toggleTask(index);
                        },
                      ),
                      trailing: IconButton(
                          onPressed: () => _deletetask(index),
                          icon: const Icon(Icons.delete))),
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _taskController,
                decoration: const InputDecoration(
                  labelText: 'Add a new task',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: _addTask,
                // onSubmitted: (value) => _addTask(value), //alternative way
              ),
            ),
            const SizedBox(width: 10.0),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addTask(_taskController.text),
              // child: const Text('Add Task'),//with ElevatedButton
            ),
          ],
        ),
      ),
    );
  }
}

class ToDoItem {
  final String title;
  bool isDone;

  ToDoItem({required this.title, this.isDone = false});
}
