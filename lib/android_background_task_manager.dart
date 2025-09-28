/// Android Background Task Manager
///
/// A Flutter package for managing background tasks on Android using WorkManager
/// and AlarmManager. This package provides a unified API for scheduling and
/// managing background tasks without needing to touch native Android code.
///
/// ## Features
///
/// - **Easy Task Registration**: Register task callbacks with unique IDs
/// - **Flexible Scheduling**: Schedule one-time or periodic tasks with various constraints
/// - **Reliable Execution**: Uses WorkManager for reliable background execution
/// - **Local Persistence**: Tracks task state across app restarts
/// - **Error Handling**: Comprehensive error handling with descriptive exceptions
/// - **Testing Support**: Built-in support for testing and debugging
///
/// ## Usage
///
/// ```dart
/// import 'package:android_background_task_manager/android_background_task_manager.dart';
///
library android_background_task_manager;

/// void main() async {
///   // Initialize the manager
///   await AndroidBackgroundTaskManager.initialize();
///
///   // Register a task
///   AndroidBackgroundTaskManager.registerTask('my_task', (id, data) async {
///     print('Task $id executed with data: $data');
///   });
///
///   // Schedule the task
///   await AndroidBackgroundTaskManager.scheduleTask(TaskOptions(
///     id: 'my_task',
///     periodic: true,
///     frequency: Duration(minutes: 30),
///   ));
/// }
/// ```
///
/// ## Requirements
///
/// - Flutter 3.0.0 or higher
/// - Android API level 21 or higher
/// - Android WorkManager and AlarmManager support
///
/// ## License
///
/// This package is licensed under the MIT License.
/// See the LICENSE file for details.

// Export the main manager class
export 'src/manager/android_background_task_manager.dart';

// Export models
export 'src/models/task_options.dart';
export 'src/models/exceptions.dart';

// Export platform-specific implementations (for advanced usage)
export 'src/platform/method_channel.dart';
export 'src/platform/persistence.dart';
