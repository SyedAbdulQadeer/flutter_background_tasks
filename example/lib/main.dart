import 'package:flutter/material.dart';
import 'package:android_background_task_manager/android_background_task_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize the Android Background Task Manager
    await AndroidBackgroundTaskManager.initialize();
    print('Background task manager initialized successfully');
  } catch (e) {
    print('Failed to initialize background task manager: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Android Background Task Manager Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Background Task Manager Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<String> _taskLogs = [];
  bool _isPeriodicTaskScheduled = false;
  bool _isOneTimeTaskScheduled = false;

  @override
  void initState() {
    super.initState();
    _registerTasks();
    _setupTaskExecutionListener();
  }

  /// Registers all background task callbacks.
  ///
  /// This method registers the callback functions that will be executed
  /// when background tasks run. Each task must be registered before
  /// it can be scheduled.
  void _registerTasks() {
    // Register periodic task
    AndroidBackgroundTaskManager.registerTask('periodic_task', (
      id,
      data,
    ) async {
      _addLog('Periodic task executed: $id');
      _addLog('Data received: $data');

      // Simulate some work
      await Future.delayed(const Duration(seconds: 2));

      _addLog('Periodic task completed: $id');
    });

    // Register one-time task
    AndroidBackgroundTaskManager.registerTask('one_time_task', (
      id,
      data,
    ) async {
      _addLog('One-time task executed: $id');
      _addLog('Data received: $data');

      // Simulate some work
      await Future.delayed(const Duration(seconds: 1));

      _addLog('One-time task completed: $id');
    });

    // Register data sync task
    AndroidBackgroundTaskManager.registerTask('data_sync_task', (
      id,
      data,
    ) async {
      _addLog('Data sync task executed: $id');

      // Simulate data synchronization
      await Future.delayed(const Duration(seconds: 3));

      _addLog('Data sync completed: $id');
    });
  }

  /// Sets up a listener for task execution events.
  ///
  /// This method listens to the task execution stream and updates
  /// the UI when tasks are executed.
  void _setupTaskExecutionListener() {
    AndroidBackgroundTaskManager.taskExecutionStream.listen((taskId) {
      _addLog('Task execution event received: $taskId');
    });
  }

  /// Adds a log entry to the task logs list.
  void _addLog(String message) {
    setState(() {
      _taskLogs.insert(
        0,
        '${DateTime.now().toString().substring(11, 19)}: $message',
      );
    });
  }

  /// Schedules a periodic task.
  Future<void> _schedulePeriodicTask() async {
    try {
      await AndroidBackgroundTaskManager.scheduleTask(
        TaskOptions(
          id: 'periodic_task',
          periodic: true,
          frequency: const Duration(
            minutes: 15,
          ), // Minimum 15 minutes for WorkManager
          initialDelay: const Duration(seconds: 5), // Start after 5 seconds
          requiresCharging: false,
          requiresWifi: false,
          retryOnFail: true,
          maxRetryAttempts: 3,
          data: {
            'type': 'periodic',
            'created_at': DateTime.now().toIso8601String(),
          },
        ),
      );

      setState(() {
        _isPeriodicTaskScheduled = true;
      });

      _addLog('Periodic task scheduled successfully');
    } catch (e) {
      _addLog('Error scheduling periodic task: $e');
    }
  }

  /// Schedules a one-time task.
  Future<void> _scheduleOneTimeTask() async {
    try {
      await AndroidBackgroundTaskManager.scheduleTask(
        TaskOptions(
          id: 'one_time_task',
          periodic: false,
          initialDelay: const Duration(seconds: 10), // Run after 10 seconds
          requiresCharging: false,
          requiresWifi: false,
          retryOnFail: true,
          data: {
            'type': 'one_time',
            'created_at': DateTime.now().toIso8601String(),
          },
        ),
      );

      setState(() {
        _isOneTimeTaskScheduled = true;
      });

      _addLog('One-time task scheduled successfully');
    } catch (e) {
      _addLog('Error scheduling one-time task: $e');
    }
  }

  /// Schedules a data sync task with WiFi requirement.
  Future<void> _scheduleDataSyncTask() async {
    try {
      await AndroidBackgroundTaskManager.scheduleTask(
        TaskOptions(
          id: 'data_sync_task',
          periodic: true,
          frequency: const Duration(
            minutes: 30,
          ), // Minimum 15 minutes, using 30 for data sync
          initialDelay: const Duration(seconds: 15), // Start after 15 seconds
          requiresCharging: false,
          requiresWifi: true, // Requires WiFi connection
          retryOnFail: true,
          maxRetryAttempts: 5,
          data: {
            'type': 'data_sync',
            'created_at': DateTime.now().toIso8601String(),
          },
        ),
      );

      _addLog('Data sync task scheduled successfully (requires WiFi)');
    } catch (e) {
      _addLog('Error scheduling data sync task: $e');
    }
  }

  /// Cancels a specific task.
  Future<void> _cancelTask(String taskId) async {
    try {
      await AndroidBackgroundTaskManager.cancelTask(taskId);

      if (taskId == 'periodic_task') {
        setState(() {
          _isPeriodicTaskScheduled = false;
        });
      } else if (taskId == 'one_time_task') {
        setState(() {
          _isOneTimeTaskScheduled = false;
        });
      }

      _addLog('Task cancelled: $taskId');
    } catch (e) {
      _addLog('Error cancelling task $taskId: $e');
    }
  }

  /// Cancels all scheduled tasks.
  Future<void> _cancelAllTasks() async {
    try {
      await AndroidBackgroundTaskManager.cancelAllTasks();

      setState(() {
        _isPeriodicTaskScheduled = false;
        _isOneTimeTaskScheduled = false;
      });

      _addLog('All tasks cancelled');
    } catch (e) {
      _addLog('Error cancelling all tasks: $e');
    }
  }

  /// Executes a task immediately for testing.
  Future<void> _executeTaskNow(String taskId) async {
    try {
      await AndroidBackgroundTaskManager.executeTaskNow(taskId);
      _addLog('Task execution initiated: $taskId');
    } catch (e) {
      _addLog('Error executing task $taskId: $e');
    }
  }

  /// Gets information about scheduled tasks.
  Future<void> _getScheduledTasks() async {
    try {
      final tasks = await AndroidBackgroundTaskManager.getScheduledTasks();
      _addLog('Scheduled tasks count: ${tasks.length}');

      for (final task in tasks) {
        _addLog('Task: ${task.id} (${task.isActive ? 'active' : 'inactive'})');
      }
    } catch (e) {
      _addLog('Error getting scheduled tasks: $e');
    }
  }

  /// Gets storage statistics.
  Future<void> _getStorageStats() async {
    try {
      final stats = await AndroidBackgroundTaskManager.getStorageStats();
      _addLog('Storage stats: $stats');
    } catch (e) {
      _addLog('Error getting storage stats: $e');
    }
  }

  /// Gets all completed task results.
  Future<void> _getTaskResults() async {
    try {
      final results = await AndroidBackgroundTaskManager.getTaskResults();
      _addLog('Task results count: ${results.length}');

      if (results.isNotEmpty) {
        results.forEach((taskId, result) {
          _addLog('Result for $taskId: $result');
        });
      } else {
        _addLog('No task results available');
      }
    } catch (e) {
      _addLog('Error getting task results: $e');
    }
  }

  /// Gets the result of a specific task.
  Future<void> _getTaskResult(String taskId) async {
    try {
      final result = await AndroidBackgroundTaskManager.getTaskResult(taskId);
      if (result != null) {
        _addLog('Result for $taskId: $result');
      } else {
        _addLog('No result available for $taskId');
      }
    } catch (e) {
      _addLog('Error getting task result for $taskId: $e');
    }
  }

  /// Clears all stored task results.
  Future<void> _clearTaskResults() async {
    try {
      await AndroidBackgroundTaskManager.clearTaskResults();
      _addLog('All task results cleared');
    } catch (e) {
      _addLog('Error clearing task results: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: _getStorageStats,
            tooltip: 'Storage Stats',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Task scheduling buttons
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Task Scheduling',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isPeriodicTaskScheduled
                                  ? null
                                  : _schedulePeriodicTask,
                              child: const Text('Schedule Periodic Task'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isOneTimeTaskScheduled
                                  ? null
                                  : _scheduleOneTimeTask,
                              child: const Text('Schedule One-time Task'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _scheduleDataSyncTask,
                        child: const Text('Schedule Data Sync Task (WiFi)'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Task management buttons
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Task Management',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isPeriodicTaskScheduled
                                  ? () => _cancelTask('periodic_task')
                                  : null,
                              child: const Text('Cancel Periodic'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isOneTimeTaskScheduled
                                  ? () => _cancelTask('one_time_task')
                                  : null,
                              child: const Text('Cancel One-time'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _cancelAllTasks,
                              child: const Text('Cancel All Tasks'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _getScheduledTasks,
                              child: const Text('Get Scheduled Tasks'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Task execution buttons
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Task Execution (Testing)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _executeTaskNow('periodic_task'),
                              child: const Text('Execute Periodic Now'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _executeTaskNow('one_time_task'),
                              child: const Text('Execute One-time Now'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _executeTaskNow('data_sync_task'),
                        child: const Text('Execute Data Sync Now'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Task results section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Task Results',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _getTaskResults,
                              child: const Text('Get All Results'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _clearTaskResults,
                              child: const Text('Clear Results'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _getTaskResult('periodic_task'),
                              child: const Text('Get Periodic Result'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _getTaskResult('one_time_task'),
                              child: const Text('Get One-time Result'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Task logs
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Task Logs',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _taskLogs.clear();
                              });
                            },
                            tooltip: 'Clear Logs',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _taskLogs.isEmpty
                          ? const Center(
                              child: Text(
                                'No task logs yet.\nSchedule and execute tasks to see logs here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _taskLogs.length,
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                print("Task Logs");
                                print(
                                  "Task logs ${index} : ${_taskLogs[index]}",
                                );

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2.0,
                                  ),
                                  child: Text(
                                    _taskLogs[index],
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
