# Flutter Background Tasks

[![pub package](https://img.shields.io/pub/v/flutter_background_tasks.svg)](https://pub.dev/packages/flutter_background_tasks)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Build Status](https://github.com/SyedAbdulQadeer/flutter_background_tasks/workflows/CI/badge.svg)](https://github.com/SyedAbdulQadeer/flutter_background_tasks/actions)

A Flutter package for managing background tasks on Android using WorkManager and AlarmManager. This package provides a unified API for scheduling and managing background tasks without needing to touch native Android code.

## Quick Start

```dart
// 1. Initialize in main()
await AndroidBackgroundTaskManager.initialize();

// 2. Register a task callback
AndroidBackgroundTaskManager.registerTask('my_task', (taskId, data) async {
  print('Background task executed: $taskId');
  // Your background work here
});

// 3. Schedule the task
await AndroidBackgroundTaskManager.scheduleTask(TaskOptions(
  id: 'my_task',
  periodic: true,
  frequency: Duration(minutes: 15), // Minimum 15 minutes
));

// 4. Get task results later
String? result = await AndroidBackgroundTaskManager.getTaskResult('my_task');
```

## Features

- **🚀 Easy Task Registration**: Register task callbacks with unique IDs
- **⏰ Flexible Scheduling**: Schedule one-time or periodic tasks with various constraints
- **🔒 Reliable Execution**: Uses WorkManager for reliable background execution
- **💾 Local Persistence**: Tracks task state across app restarts
- **� Task Results**: Retrieve and monitor background task execution results
- **�🛡️ Error Handling**: Comprehensive error handling with descriptive exceptions
- **🧪 Testing Support**: Built-in support for testing and debugging
- **📱 Android Only**: Optimized specifically for Android platform

## Requirements

- Flutter 3.0.0 or higher
- Android API level 21 or higher
- Android WorkManager and AlarmManager support

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_background_tasks: ^1.0.0
```

Then run:

```bash
flutter pub get
```

### Android Setup

Add the following permissions to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

For Android 12+ (API 31+), you may also need:

```xml
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
```

### Proguard Rules

If you're building a release APK with code obfuscation, add these rules to your `android/app/proguard-rules.pro`:

```
-keep class com.example.flutter_background_tasks.** { *; }
-keep class androidx.work.** { *; }
```

## Usage

### 1. Initialize the Manager

First, initialize the Android Background Task Manager in your `main()` function:

```dart
import 'package:flutter_background_tasks/flutter_background_tasks.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the manager
  await AndroidBackgroundTaskManager.initialize();
  
  runApp(MyApp());
}
```

### 2. Register Task Callbacks

Register the functions that will be executed when background tasks run:

```dart
// Register a periodic data sync task
AndroidBackgroundTaskManager.registerTask('data_sync', (taskId, data) async {
  print('Data sync task executed: $taskId');
  
  // Perform your background work here
  await syncUserData();
  await updateLocalCache();
  
  print('Data sync completed');
});

// Register a one-time notification task
AndroidBackgroundTaskManager.registerTask('send_notification', (taskId, data) async {
  print('Notification task executed: $taskId');
  
  // Send notification
  await sendLocalNotification(data['title'], data['message']);
});
```

### 3. Schedule Tasks

Schedule tasks with various options:

```dart
// Schedule a periodic task (runs every 30 minutes - minimum 15 minutes required)
await AndroidBackgroundTaskManager.scheduleTask(TaskOptions(
  id: 'data_sync',
  periodic: true,
  frequency: Duration(minutes: 30), // Minimum 15 minutes for periodic tasks
  initialDelay: Duration(seconds: 10),
  requiresCharging: false,
  requiresWifi: true, // Only run on WiFi
  retryOnFail: true,
  maxRetryAttempts: 3,
  data: {'sync_type': 'full'},
));

// Schedule a one-time task (runs once after 1 hour)
await AndroidBackgroundTaskManager.scheduleTask(TaskOptions(
  id: 'send_notification',
  periodic: false,
  initialDelay: Duration(hours: 1),
  requiresCharging: true, // Only run when charging
  retryOnFail: true,
  data: {
    'title': 'Reminder',
    'message': 'Don\'t forget to check your data!',
  },
));
```

### 4. Manage Tasks

```dart
// Check if a task is scheduled
bool isScheduled = await AndroidBackgroundTaskManager.isTaskScheduled('data_sync');

// Get all scheduled tasks
List<ScheduledTaskInfo> tasks = await AndroidBackgroundTaskManager.getScheduledTasks();

// Cancel a specific task
await AndroidBackgroundTaskManager.cancelTask('data_sync');

// Cancel all tasks
await AndroidBackgroundTaskManager.cancelAllTasks();

// Execute a task immediately (for testing)
await AndroidBackgroundTaskManager.executeTaskNow('data_sync');
```

### 5. Monitor Task Results

Background tasks store their execution results which you can retrieve:

```dart
// Get all completed task results
Map<String, String> allResults = await AndroidBackgroundTaskManager.getTaskResults();
print('All task results: $allResults');

// Get result of a specific task
String? taskResult = await AndroidBackgroundTaskManager.getTaskResult('data_sync');
if (taskResult != null) {
  print('Data sync result: $taskResult');
}

// Clear all stored task results (for cleanup)
await AndroidBackgroundTaskManager.clearTaskResults();
```

**Note**: Task results are stored by the native Android implementation when background tasks complete. Since background tasks run in worker threads, they cannot directly communicate with Flutter. Instead, they store results in shared preferences which can be retrieved when the Flutter app is active.

```

## Task Options

The `TaskOptions` class provides comprehensive configuration for background tasks:

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `id` | `String` | Unique identifier for the task | Required |
| `periodic` | `bool` | Whether the task repeats | `false` |
| `frequency` | `Duration?` | How often to repeat (periodic only) | Required if periodic |
| `initialDelay` | `Duration` | Delay before first execution | `Duration.zero` |
| `requiresCharging` | `bool` | Only run when device is charging | `false` |
| `requiresWifi` | `bool` | Only run when connected to WiFi | `false` |
| `retryOnFail` | `bool` | Retry on failure with exponential backoff | `true` |
| `maxRetryAttempts` | `int` | Maximum number of retry attempts | `5` |
| `data` | `Map<String, dynamic>?` | Additional data to pass to task | `null` |

## Constraints and Limitations

### WorkManager Requirements

- **Minimum Frequency**: Periodic tasks must have a frequency of at least 15 minutes
- **Battery Optimization**: Tasks may be delayed or cancelled by the system to save battery
- **Doze Mode**: Tasks are paused when the device enters doze mode

### Task Data

- Task data must be JSON serializable
- Large data payloads may impact performance
- Sensitive data should be encrypted before passing to tasks

### Best Practices

1. **Use appropriate constraints**: Only use `requiresCharging` and `requiresWifi` when necessary
2. **Handle failures gracefully**: Always implement proper error handling in task callbacks
3. **Keep tasks lightweight**: Background tasks should complete quickly to avoid being killed
4. **Test thoroughly**: Use `executeTaskNow()` for testing task logic

## Error Handling

The package provides comprehensive error handling with specific exception types:

```dart
try {
  await AndroidBackgroundTaskManager.scheduleTask(options);
} on DuplicateTaskIdException catch (e) {
  print('Task ID already exists: ${e.message}');
} on TaskNotRegisteredException catch (e) {
  print('Task not registered: ${e.message}');
} on InvalidTaskOptionsException catch (e) {
  print('Invalid task options: ${e.message}');
} on InvalidFrequencyException catch (e) {
  print('Frequency too low: ${e.message}');
} on NativeOperationException catch (e) {
  print('Native operation failed: ${e.message}');
} on PersistenceException catch (e) {
  print('Persistence error: ${e.message}');
}
```

## Monitoring and Debugging

### Task Execution Stream

Listen to task execution events:

```dart
AndroidBackgroundTaskManager.taskExecutionStream.listen((taskId) {
  print('Task executed: $taskId');
});
```

### Storage Statistics

Get information about task storage:

```dart
Map<String, dynamic> stats = await AndroidBackgroundTaskManager.getStorageStats();
print('Total tasks: ${stats['totalTasks']}');
print('Active tasks: ${stats['activeTasks']}');
print('Total executions: ${stats['totalExecutions']}');
```

### Debug Information

```dart
// Check if manager is initialized
bool isInitialized = AndroidBackgroundTaskManager.isInitialized;

// Get task counts
int registeredCount = AndroidBackgroundTaskManager.registeredTaskCount;
int scheduledCount = AndroidBackgroundTaskManager.scheduledTaskCount;
```

## Example App

Check out the `example/` directory for a complete Flutter app demonstrating all features of the Android Background Task Manager.

To run the example:

```bash
cd example
flutter run
```

## Testing

The package includes comprehensive unit tests. To run them:

```bash
flutter test
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes and version history.

## Support

If you encounter any issues or have questions, please:

1. Check the [Issues](https://github.com/SyedAbdulQadeer/flutter_background_tasks/issues) page
2. Create a new issue with detailed information
3. Include Flutter version, Android API level, and error logs

## Roadmap

- [ ] iOS support using Background App Refresh
- [ ] Task dependency management
- [ ] Advanced scheduling patterns (cron-like)
- [ ] Task execution analytics
- [ ] Background task debugging tools

---

Made with ❤️ for the Flutter community