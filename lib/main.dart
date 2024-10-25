import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
// added to pubspec.yaml file
//  flutter_local_notifications: ^17.2.3
// shared_preferences: ^2.3.2
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To Do List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  List<Task> tasks = [];
  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void scheduleTaskNotification(Task task) async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      task.hashCode,
      'Reminder: ${task.title}',
      'Task "${task.title}" is ${task.status} and due on ${task.dueDate}',
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList('tasks') ?? [];

    setState(() {
      tasks = tasksJson.map((taskJson) {
        Map<String, dynamic> taskMap = json.decode(taskJson);
        return Task(
          taskMap['title'],
          taskMap['description'],
          taskMap['duration'].toDouble(),
          taskMap['status'],
          DateTime.parse(taskMap['dueDate']),
        );
      }).toList();
    });
  }

  static List<Widget> _widgetOptions(
      List<Task> tasks, Function(Task) addTask, Function() saveTasks) {
    return <Widget>[
      TaskManager(
        tasks: tasks,
        onAddTask: addTask,
        onSave: saveTasks,
      ),
      Completedtask(tasks: tasks),
    ];
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = tasks
        .map((task) => json.encode({
              'title': task.title,
              'description': task.description,
              'duration': task.duration,
              'status': task.status,
              'dueDate': task.dueDate.toIso8601String(),
            }))
        .toList();

    await prefs.setStringList('tasks', tasksJson);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _addTask(Task task) {
    setState(() {
      tasks.add(task);
      _saveTasks();
      if (task.status == 'Not Started' || task.status == 'In Progress') {
        scheduleTaskNotification(task);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A90E2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90E2),
        title: const Padding(
          padding: EdgeInsets.all(15),
          child: Text(
            'To Do List',
            textAlign: TextAlign.left,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 20.0,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF50A7C2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _widgetOptions(tasks, _addTask, _saveTasks)
            .elementAt(_selectedIndex),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue[400],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTask(onAdd: _addTask, title: 'Add Task'),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Task',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Completed Task',
          ),
        ],
        currentIndex: _selectedIndex,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        enableFeedback: false,
        useLegacyColorScheme: false,
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.blue[200],
        onTap: _onItemTapped,
      ),
    );
  }
}

class TaskManager extends StatefulWidget {
  final List<Task> tasks;
  final Function(Task) onAddTask;
  final Function() onSave;

  const TaskManager({
    super.key,
    required this.tasks,
    required this.onAddTask,
    required this.onSave,
  });

  @override
  State<TaskManager> createState() => _TaskManagerState();
}

class _TaskManagerState extends State<TaskManager> {
  @override
  Widget build(BuildContext context) {
    return widget.tasks.isEmpty
        ? const Center(
            child: Text(
            "No Task is found",
            style: TextStyle(fontSize: 20.0, color: Colors.white),
          ))
        : ListView.builder(
            itemCount: widget.tasks.length,
            itemBuilder: (BuildContext context, int index) {
              return Container(
                  margin: const EdgeInsets.fromLTRB(30, 12, 30, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.blue.shade300),
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: widget.tasks[index].status == 'Not Started'
                        ? const Icon(Icons.circle, color: Colors.red)
                        : widget.tasks[index].status == 'In Progress'
                            ? const Icon(Icons.circle, color: Colors.yellow)
                            : const Icon(Icons.circle, color: Colors.green),
                    title: Text(widget.tasks[index].title),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddTask(
                            task: widget.tasks[index],
                            onAdd: (newTask) {
                              setState(() {
                                widget.tasks[index] = newTask;
                                widget.onSave();
                              });
                            },
                            title: 'Edit Task',
                          ),
                        ),
                      );
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Delete Task'),
                                content: const Text(
                                    'Are you sure you want to delete this task?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        widget.tasks.removeAt(index);
                                        widget.onSave();
                                      });
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Task deleted successfully',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    },
                                    child: const Text('OK'),
                                  ),
                                ],
                              );
                            });
                      },
                    ),
                  ));
            },
          );
  }
}

class Completedtask extends StatelessWidget {
  final List<Task> tasks;

  const Completedtask({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    List<Task> completedTasks =
        tasks.where((task) => task.status == 'Completed').toList();

    return Column(
      children: [
        Expanded(
          child: completedTasks.isEmpty
              ? const Center(
                  child: Text('No Completed Task Found',
                      style: TextStyle(fontSize: 20.0, color: Colors.white)),
                )
              : ListView.builder(
                  itemCount: completedTasks.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Container(
                      margin: const EdgeInsets.fromLTRB(30, 12, 30, 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.blue.shade300),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: ListTile(
                        leading:
                            const Icon(Icons.check_circle, color: Colors.green),
                        title: Text(completedTasks[index].title),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text(
                                  'Task Details',
                                  style: TextStyle(
                                      color: Colors.blue, fontSize: 20.0),
                                ),
                                content: Text.rich(
                                  TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'Title: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red),
                                      ),
                                      TextSpan(
                                        text:
                                            '${completedTasks[index].title}\n',
                                      ),
                                      const TextSpan(
                                        text: 'Description: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red),
                                      ),
                                      TextSpan(
                                        text:
                                            '${completedTasks[index].description}\n',
                                      ),
                                      const TextSpan(
                                        text: 'Duration: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red),
                                      ),
                                      TextSpan(
                                        text:
                                            '${completedTasks[index].duration}\n',
                                      ),
                                      const TextSpan(
                                        text: 'Due Date: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red),
                                      ),
                                      TextSpan(
                                        text:
                                            '${completedTasks[index].dueDate}',
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text('OK'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text('Total Completed Tasks: ${completedTasks.length}',
              style: const TextStyle(fontSize: 20.0, color: Colors.white)),
        ),
      ],
    );
  }
}

class AddTask extends StatefulWidget {
  final Task? task;
  final void Function(Task) onAdd;
  final String title;
  const AddTask(
      {super.key, this.task, required this.onAdd, required this.title});

  @override
  State<AddTask> createState() => _AddTaskState();
}

class _AddTaskState extends State<AddTask> {
  final TextEditingController titlecontroller = TextEditingController();
  final TextEditingController description = TextEditingController();
  final TextEditingController duration = TextEditingController();
  final TextEditingController status = TextEditingController();
  final TextEditingController dueDate = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      titlecontroller.text = widget.task!.title;
      description.text = widget.task!.description;
      duration.text = widget.task!.duration.toString();
      status.text = widget.task!.status;
      dueDate.text = widget.task!.dueDate.toString();
    }
  }

  void addTask() {
    List<String> errors = [];
    if (titlecontroller.text.isEmpty) {
      errors.add('Title cannot be empty');
    }
    if (status.text.isEmpty) {
      errors.add('Status cannot be empty');
    }
    if (dueDate.text.isEmpty) {
      errors.add('Due Date cannot be empty');
    }
    if (errors.isNotEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'Error',
              style: TextStyle(color: Colors.red),
            ),
            content: Text(
              errors.join('\n'),
              style: const TextStyle(color: Colors.red),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }
    Task newTask = Task(
      titlecontroller.text,
      description.text,
      duration.text.isNotEmpty ? double.parse(duration.text) : 0.0,
      status.text,
      DateTime.parse(dueDate.text),
    );
    setState(() {
      widget.onAdd(newTask);
    });
    String successMessage = widget.task == null
        ? 'Task added successfully'
        : 'Task updated successfully';
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Success',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            successMessage,
            style: const TextStyle(fontSize: 16.0),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    titlecontroller.clear();
    description.clear();
    duration.clear();
    status.clear();
    dueDate.clear();
  }

  @override
  void dispose() {
    titlecontroller.dispose();
    description.dispose();
    duration.dispose();
    status.dispose();
    dueDate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90E2),
        title: Text(widget.title,
            style: const TextStyle(color: Colors.white, fontSize: 20.0)),
      ),
      body: SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A90E2), Color(0xFF50A7C2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add New Task',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.title, color: Colors.blue),
                    title: TextField(
                      controller: titlecontroller,
                      decoration: const InputDecoration(
                        labelText: 'Enter Title',
                        labelStyle: TextStyle(color: Colors.blue),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.description, color: Colors.blue),
                    title: TextField(
                      controller: description,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: Colors.blue),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.timer, color: Colors.blue),
                    title: TextField(
                      controller: duration,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Enter Duration',
                        labelStyle: TextStyle(color: Colors.blue),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.flag, color: Colors.blue),
                      title: DropdownButtonFormField<String>(
                        value: status.text.isNotEmpty ? status.text : null,
                        decoration: const InputDecoration(
                          labelText: 'Select Status',
                          labelStyle:
                              TextStyle(color: Colors.blue, fontSize: 18.0),
                          border: InputBorder.none,
                        ),
                        items: ['Not Started', 'In Progress', 'Completed']
                            .map((String value) {
                          Color textColor;
                          switch (value) {
                            case 'Not Started':
                              textColor = Colors.red;
                              break;
                            case 'In Progress':
                              textColor = Colors.yellow;
                              break;
                            case 'Completed':
                              textColor = Colors.green;
                              break;
                            default:
                              textColor = Colors.black;
                          }
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(color: textColor),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            status.text = newValue!;
                          });
                        },
                      ),
                    )),
                Container(
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading:
                        const Icon(Icons.calendar_today, color: Colors.blue),
                    title: TextButton(
                      onPressed: () {
                        showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(DateTime.now().year),
                          lastDate: DateTime(DateTime.now().year + 5),
                        ).then((DateTime? value) {
                          if (value != null) {
                            setState(() {
                              dueDate.text = value.toString();
                            });
                          }
                        });
                      },
                      child: Text(
                        dueDate.text.isEmpty ? 'Select Due Date' : dueDate.text,
                        style: TextStyle(
                          color:
                              dueDate.text.isEmpty ? Colors.blue : Colors.blue,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: addTask,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      widget.task == null ? 'Add Task' : 'Update Task',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Task {
  String title;
  String description;
  double duration;
  String status;
  DateTime dueDate;
  Task(this.title, this.description, this.duration, this.status, this.dueDate);
}
