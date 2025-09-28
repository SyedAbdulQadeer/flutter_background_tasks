import 'dart:async';
import 'package:flutter/services.dart';
import '../models/exceptions.dart';
import '../models/task_options.dart';
import '../platform/method_channel.dart';
import '../platform/persistence.dart';

/// Main manager class for Android background tasks.
///
/// This class provides a unified API for scheduling and managing background
/// tasks on Android using WorkManager and AlarmManager internally. It handles
/// task registration, scheduling, cancellation, and execution tracking.
///
/// Example usage:
/// ```dart
/// // Initialize the manager
/// await AndroidBackgroundTaskManager.initialize();
///
/// // Register a task
/// AndroidBackgroundTaskManager.registerTask('my_task', (id, data) async {
///   print('Task $id executed with data: $data');
/// });
///
/// // Schedule the task
/// await AndroidBackgroundTaskManager.scheduleTask(TaskOptions(
///   id: 'my_task',
///   periodic: true,
///   frequency: Duration(minutes: 30),
/// ));
/// ```
class AndroidBackgroundTaskManager {
  static bool _isInitialized = false;
  static final Map<String, BackgroundTaskCallback> _registeredTasks = {};
  static final Map<String, ScheduledTaskInfo> _scheduledTasks = {};
  static StreamController<String>? _taskExecutionController;

  /// Initializes the Android Background Task Manager.
  ///
  /// This method must be called before any other operations can be performed.
  /// It sets up the necessary communication channels with the native Android
  /// side and prepares the system for task management.
  ///
  /// Throws [NativeOperationException] if initialization fails.
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize the native Android side
      await AndroidBackgroundTaskMethodChannel.initialize();

      // Set up method call handler for task execution
      AndroidBackgroundTaskMethodChannel.setMethodCallHandler(
        _handleMethodCall,
      );

      // Load existing scheduled tasks from persistence
      await _loadScheduledTasks();

      // Perform cleanup of old tasks
      await TaskPersistence.cleanupOldTasks();

      _isInitialized = true;
    } catch (e) {
      throw NativeOperationException('initialize', e.toString());
    }
  }

  /// Registers a background task callback.
  ///
  /// This method registers a callback function that will be executed when
  /// the background task runs. Each task must be registered before it can
  /// be scheduled.
  ///
  /// [taskId] Unique identifier for the task.
  /// [callback] Function to execute when the task runs.
  ///
  /// Throws [DuplicateTaskIdException] if a task with the same ID is already registered.
  static void registerTask(String taskId, BackgroundTaskCallback callback) {
    if (_registeredTasks.containsKey(taskId)) {
      throw DuplicateTaskIdException(taskId);
    }

    _registeredTasks[taskId] = callback;
  }

  /// Unregisters a background task callback.
  ///
  /// This method removes the callback function for the specified task ID.
  /// The task can no longer be executed after unregistration.
  ///
  /// [taskId] Unique identifier for the task to unregister.
  static void unregisterTask(String taskId) {
    _registeredTasks.remove(taskId);
  }

  /// Schedules a background task.
  ///
  /// This method schedules a task to run according to the provided options.
  /// The task must be registered before it can be scheduled.
  ///
  /// [options] Configuration options for the task.
  ///
  /// Throws [NotInitializedException] if the manager is not initialized.
  /// Throws [TaskNotRegisteredException] if the task is not registered.
  /// Throws [InvalidTaskOptionsException] if the options are invalid.
  /// Throws [NativeOperationException] if scheduling fails.
  static Future<void> scheduleTask(TaskOptions options) async {
    if (!_isInitialized) {
      throw const NotInitializedException();
    }

    if (!_registeredTasks.containsKey(options.id)) {
      throw TaskNotRegisteredException(options.id);
    }

    // Validate options
    options.validate();

    try {
      // Schedule on native side
      await AndroidBackgroundTaskMethodChannel.scheduleTask(options);

      // Create task info
      final taskInfo = ScheduledTaskInfo(
        id: options.id,
        options: options,
        isActive: true,
        executionCount: 0,
        failureCount: 0,
        scheduledAt: DateTime.now(),
      );

      // Save to persistence
      await TaskPersistence.saveTask(taskInfo);
      _scheduledTasks[options.id] = taskInfo;
    } catch (e) {
      if (e is AndroidBackgroundTaskException) rethrow;
      throw NativeOperationException('scheduleTask', e.toString());
    }
  }

  /// Cancels a scheduled background task.
  ///
  /// This method cancels the task with the specified ID, removing it from
  /// both the native Android side and local persistence.
  ///
  /// [taskId] Unique identifier of the task to cancel.
  ///
  /// Throws [NotInitializedException] if the manager is not initialized.
  /// Throws [NativeOperationException] if cancellation fails.
  static Future<void> cancelTask(String taskId) async {
    if (!_isInitialized) {
      throw const NotInitializedException();
    }

    try {
      // Cancel on native side
      await AndroidBackgroundTaskMethodChannel.cancelTask(taskId);

      // Update local state
      await TaskPersistence.updateTaskStatus(taskId, false);
      _scheduledTasks.remove(taskId);
    } catch (e) {
      if (e is AndroidBackgroundTaskException) rethrow;
      throw NativeOperationException('cancelTask', e.toString());
    }
  }

  /// Cancels all scheduled background tasks.
  ///
  /// This method cancels all tasks that have been scheduled through this
  /// manager, clearing both the native Android side and local persistence.
  ///
  /// Throws [NotInitializedException] if the manager is not initialized.
  /// Throws [NativeOperationException] if cancellation fails.
  static Future<void> cancelAllTasks() async {
    if (!_isInitialized) {
      throw const NotInitializedException();
    }

    try {
      // Cancel all on native side
      await AndroidBackgroundTaskMethodChannel.cancelAllTasks();

      // Clear local state
      await TaskPersistence.clearAllTasks();
      _scheduledTasks.clear();
    } catch (e) {
      if (e is AndroidBackgroundTaskException) rethrow;
      throw NativeOperationException('cancelAllTasks', e.toString());
    }
  }

  /// Gets information about all currently scheduled tasks.
  ///
  /// This method returns a list of ScheduledTaskInfo objects describing
  /// all tasks that are currently scheduled and active.
  ///
  /// Returns a list of ScheduledTaskInfo objects.
  ///
  /// Throws [NotInitializedException] if the manager is not initialized.
  static Future<List<ScheduledTaskInfo>> getScheduledTasks() async {
    if (!_isInitialized) {
      throw const NotInitializedException();
    }

    return _scheduledTasks.values.toList();
  }

  /// Checks if a specific task is currently scheduled.
  ///
  /// This method checks whether a task with the specified ID is currently
  /// scheduled and active.
  ///
  /// [taskId] Unique identifier of the task to check.
  ///
  /// Returns true if the task is scheduled and active, false otherwise.
  ///
  /// Throws [NotInitializedException] if the manager is not initialized.
  static Future<bool> isTaskScheduled(String taskId) async {
    if (!_isInitialized) {
      throw const NotInitializedException();
    }

    return _scheduledTasks.containsKey(taskId) &&
        _scheduledTasks[taskId]!.isActive;
  }

  /// Executes a task immediately for testing purposes.
  ///
  /// This method is primarily used for testing and debugging. It allows
  /// immediate execution of a task without waiting for its scheduled time.
  ///
  /// [taskId] Unique identifier of the task to execute.
  ///
  /// Throws [NotInitializedException] if the manager is not initialized.
  /// Throws [TaskNotRegisteredException] if the task is not registered.
  /// Throws [NativeOperationException] if execution fails.
  static Future<void> executeTaskNow(String taskId) async {
    if (!_isInitialized) {
      throw const NotInitializedException();
    }

    if (!_registeredTasks.containsKey(taskId)) {
      throw TaskNotRegisteredException(taskId);
    }

    try {
      await AndroidBackgroundTaskMethodChannel.executeTaskNow(taskId);
    } catch (e) {
      if (e is AndroidBackgroundTaskException) rethrow;
      throw NativeOperationException('executeTaskNow', e.toString());
    }
  }

  /// Gets a stream of task execution events.
  ///
  /// This method returns a stream that emits task IDs when tasks are executed.
  /// This can be useful for monitoring task execution and debugging.
  ///
  /// Returns a stream of task IDs.
  static Stream<String> get taskExecutionStream {
    _taskExecutionController ??= StreamController<String>.broadcast();
    return _taskExecutionController!.stream;
  }

  /// Checks if the manager is initialized.
  ///
  /// Returns true if the manager has been initialized, false otherwise.
  static bool get isInitialized => _isInitialized;

  /// Gets the number of registered tasks.
  ///
  /// Returns the number of tasks that have been registered.
  static int get registeredTaskCount => _registeredTasks.length;

  /// Gets the number of scheduled tasks.
  ///
  /// Returns the number of tasks that are currently scheduled.
  static int get scheduledTaskCount => _scheduledTasks.length;

  /// Gets storage statistics for debugging purposes.
  ///
  /// This method returns information about the current state of task storage,
  /// including counts and execution statistics.
  ///
  /// Returns a map containing storage statistics.
  ///
  /// Throws [NotInitializedException] if the manager is not initialized.
  static Future<Map<String, dynamic>> getStorageStats() async {
    if (!_isInitialized) {
      throw const NotInitializedException();
    }

    return await TaskPersistence.getStorageStats();
  }

  /// Gets all completed task results from native storage.
  ///
  /// This method retrieves all background task results that have been
  /// stored by the native Android implementation. Results are stored
  /// when background tasks complete their execution.
  ///
  /// Returns a map where keys are task IDs and values are task results.
  ///
  /// Throws [NotInitializedException] if the manager is not initialized.
  /// Throws [NativeOperationException] if retrieval fails.
  static Future<Map<String, String>> getTaskResults() async {
    if (!_isInitialized) {
      throw const NotInitializedException();
    }

    try {
      final results = await AndroidBackgroundTaskMethodChannel.getTaskResults();
      return Map<String, String>.from(results);
    } catch (e) {
      if (e is AndroidBackgroundTaskException) rethrow;
      throw NativeOperationException('getTaskResults', e.toString());
    }
  }

  /// Gets the result of a specific completed task.
  ///
  /// This method retrieves the result of a specific background task
  /// that has completed execution.
  ///
  /// [taskId] The unique identifier of the task whose result to retrieve.
  ///
  /// Returns the task result as a string, or null if no result is available.
  ///
  /// Throws [NotInitializedException] if the manager is not initialized.
  /// Throws [NativeOperationException] if retrieval fails.
  static Future<String?> getTaskResult(String taskId) async {
    if (!_isInitialized) {
      throw const NotInitializedException();
    }

    try {
      return await AndroidBackgroundTaskMethodChannel.getTaskResult(taskId);
    } catch (e) {
      if (e is AndroidBackgroundTaskException) rethrow;
      throw NativeOperationException('getTaskResult', e.toString());
    }
  }

  /// Clears all stored task results from native storage.
  ///
  /// This method removes all task results that have been stored by
  /// completed background tasks. Use this to clean up storage space.
  ///
  /// Throws [NotInitializedException] if the manager is not initialized.
  /// Throws [NativeOperationException] if clearing fails.
  static Future<void> clearTaskResults() async {
    if (!_isInitialized) {
      throw const NotInitializedException();
    }

    try {
      await AndroidBackgroundTaskMethodChannel.clearTaskResults();
    } catch (e) {
      if (e is AndroidBackgroundTaskException) rethrow;
      throw NativeOperationException('clearTaskResults', e.toString());
    }
  }

  /// Handles method calls from the native Android side.
  ///
  /// This method processes incoming method calls from the native side,
  /// primarily for task execution callbacks.
  ///
  /// [call] The method call from the native side.
  ///
  /// Returns the result of the method call.
  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'executeTask':
        return await _executeTask(
          call.arguments['taskId'] as String,
          call.arguments['data'] as Map<String, dynamic>?,
        );
      default:
        throw PlatformException(
          code: 'UNKNOWN_METHOD',
          message: 'Unknown method: ${call.method}',
        );
    }
  }

  /// Executes a registered task callback.
  ///
  /// This method finds the registered callback for the specified task ID
  /// and executes it with the provided data.
  ///
  /// [taskId] Unique identifier of the task to execute.
  /// [data] Additional data to pass to the task callback.
  ///
  /// Returns the result of the task execution.
  static Future<dynamic> _executeTask(
    String taskId,
    Map<String, dynamic>? data,
  ) async {
    final callback = _registeredTasks[taskId];
    if (callback == null) {
      throw TaskNotRegisteredException(taskId);
    }

    try {
      // Update execution count
      await TaskPersistence.updateTaskExecution(taskId);

      // Execute the callback
      await callback(taskId, data);

      // Emit execution event
      _taskExecutionController?.add(taskId);

      return {'success': true};
    } catch (e) {
      // Update failure count
      await TaskPersistence.updateTaskFailure(taskId);

      // Re-throw the error
      rethrow;
    }
  }

  /// Loads scheduled tasks from persistence.
  ///
  /// This method loads all scheduled tasks from local storage and populates
  /// the internal task cache.
  static Future<void> _loadScheduledTasks() async {
    try {
      final tasks = await TaskPersistence.loadAllTasks();
      _scheduledTasks.clear();

      for (final task in tasks) {
        if (task.isActive) {
          _scheduledTasks[task.id] = task;
        }
      }
    } catch (e) {
      // Log error but don't throw - this is not critical for initialization
      print('Warning: Failed to load scheduled tasks: $e');
    }
  }

  /// Resets the manager to its initial state.
  ///
  /// This method clears all registered tasks, scheduled tasks, and resets
  /// the initialization state. It should only be used for testing purposes.
  ///
  /// Note: This method is not part of the public API and should only be
  /// used internally or in tests.
  static void reset() {
    _isInitialized = false;
    _registeredTasks.clear();
    _scheduledTasks.clear();
    _taskExecutionController?.close();
    _taskExecutionController = null;
    AndroidBackgroundTaskMethodChannel.removeMethodCallHandler();
  }
}
