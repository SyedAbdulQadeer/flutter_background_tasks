import 'dart:async';
import 'package:flutter/services.dart';
import '../models/exceptions.dart';
import '../models/task_options.dart';

/// Method channel for communicating with native Android code.
///
/// This class handles all communication between the Flutter side and the
/// native Android implementation. It provides a clean interface for
/// scheduling, canceling, and managing background tasks.
class AndroidBackgroundTaskMethodChannel {
  /// The method channel used for communication with native code.
  ///
  /// This channel name must match the one used in the native Android code.
  static const MethodChannel _channel = MethodChannel(
    'android_background_task_manager',
  );

  /// Initializes the native Android side of the background task manager.
  ///
  /// This method must be called before any other operations can be performed.
  /// It sets up the necessary communication channels and initializes
  /// the native Android WorkManager and AlarmManager systems.
  ///
  /// Throws [NativeOperationException] if initialization fails.
  static Future<void> initialize() async {
    try {
      await _channel.invokeMethod('initialize');
    } on PlatformException catch (e) {
      throw NativeOperationException(
        'initialize',
        e.message ?? 'Unknown error',
      );
    }
  }

  /// Schedules a background task on the native Android side.
  ///
  /// This method converts the Dart TaskOptions to a format that the native
  /// Android code can understand and schedules the task using either
  /// WorkManager (for periodic/reliable tasks) or AlarmManager (for simple
  /// one-time tasks).
  ///
  /// [options] The task configuration options.
  ///
  /// Throws [NativeOperationException] if scheduling fails.
  static Future<void> scheduleTask(TaskOptions options) async {
    try {
      await _channel.invokeMethod('scheduleTask', options.toMap());
    } on PlatformException catch (e) {
      throw NativeOperationException(
        'scheduleTask',
        e.message ?? 'Unknown error',
      );
    }
  }

  /// Cancels a scheduled background task.
  ///
  /// This method cancels the task with the specified ID on the native
  /// Android side. The task will be removed from both WorkManager and
  /// AlarmManager if it exists in either system.
  ///
  /// [taskId] The unique identifier of the task to cancel.
  ///
  /// Throws [NativeOperationException] if cancellation fails.
  static Future<void> cancelTask(String taskId) async {
    try {
      await _channel.invokeMethod('cancelTask', {'taskId': taskId});
    } on PlatformException catch (e) {
      throw NativeOperationException(
        'cancelTask',
        e.message ?? 'Unknown error',
      );
    }
  }

  /// Cancels all scheduled background tasks.
  ///
  /// This method cancels all tasks that have been scheduled through this
  /// manager. It clears both WorkManager and AlarmManager queues.
  ///
  /// Throws [NativeOperationException] if cancellation fails.
  static Future<void> cancelAllTasks() async {
    try {
      await _channel.invokeMethod('cancelAllTasks');
    } on PlatformException catch (e) {
      throw NativeOperationException(
        'cancelAllTasks',
        e.message ?? 'Unknown error',
      );
    }
  }

  /// Gets information about all currently scheduled tasks.
  ///
  /// This method retrieves the current state of all scheduled tasks from
  /// the native Android side, including their configuration and execution
  /// status.
  ///
  /// Returns a list of ScheduledTaskInfo objects describing each task.
  ///
  /// Throws [NativeOperationException] if retrieval fails.
  static Future<List<ScheduledTaskInfo>> getScheduledTasks() async {
    try {
      final result = await _channel.invokeMethod('getScheduledTasks');
      final List<dynamic> taskList = result as List<dynamic>;
      return taskList
          .map(
            (taskMap) =>
                ScheduledTaskInfo.fromMap(taskMap as Map<String, dynamic>),
          )
          .toList();
    } on PlatformException catch (e) {
      throw NativeOperationException(
        'getScheduledTasks',
        e.message ?? 'Unknown error',
      );
    }
  }

  /// Checks if a specific task is currently scheduled.
  ///
  /// This method queries the native Android side to determine if a task
  /// with the specified ID is currently scheduled and active.
  ///
  /// [taskId] The unique identifier of the task to check.
  ///
  /// Returns true if the task is scheduled and active, false otherwise.
  ///
  /// Throws [NativeOperationException] if the check fails.
  static Future<bool> isTaskScheduled(String taskId) async {
    try {
      final result = await _channel.invokeMethod('isTaskScheduled', {
        'taskId': taskId,
      });
      return result as bool;
    } on PlatformException catch (e) {
      throw NativeOperationException(
        'isTaskScheduled',
        e.message ?? 'Unknown error',
      );
    }
  }

  /// Executes a task immediately for testing purposes.
  ///
  /// This method is primarily used for testing and debugging. It allows
  /// immediate execution of a task without waiting for its scheduled time.
  ///
  /// [taskId] The unique identifier of the task to execute.
  ///
  /// Throws [NativeOperationException] if execution fails.
  static Future<void> executeTaskNow(String taskId) async {
    try {
      await _channel.invokeMethod('executeTaskNow', {'taskId': taskId});
    } on PlatformException catch (e) {
      throw NativeOperationException(
        'executeTaskNow',
        e.message ?? 'Unknown error',
      );
    }
  }

  /// Gets all completed task results from native storage.
  ///
  /// This method retrieves all background task results that have been
  /// stored by the native Android implementation.
  ///
  /// Returns a map where keys are task IDs and values are task results.
  ///
  /// Throws [NativeOperationException] if retrieval fails.
  static Future<Map<String, dynamic>> getTaskResults() async {
    try {
      final result = await _channel.invokeMethod('getTaskResults');
      return Map<String, dynamic>.from(result as Map);
    } on PlatformException catch (e) {
      throw NativeOperationException(
        'getTaskResults',
        e.message ?? 'Unknown error',
      );
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
  /// Throws [NativeOperationException] if retrieval fails.
  static Future<String?> getTaskResult(String taskId) async {
    try {
      final result = await _channel.invokeMethod('getTaskResult', {
        'taskId': taskId,
      });
      return result as String?;
    } on PlatformException catch (e) {
      throw NativeOperationException(
        'getTaskResult',
        e.message ?? 'Unknown error',
      );
    }
  }

  /// Clears all stored task results from native storage.
  ///
  /// This method removes all task results that have been stored by
  /// completed background tasks.
  ///
  /// Throws [NativeOperationException] if clearing fails.
  static Future<void> clearTaskResults() async {
    try {
      await _channel.invokeMethod('clearTaskResults');
    } on PlatformException catch (e) {
      throw NativeOperationException(
        'clearTaskResults',
        e.message ?? 'Unknown error',
      );
    }
  }

  /// Sets up a method call handler for receiving callbacks from native code.
  ///
  /// This method sets up a handler that will be called when the native
  /// Android side needs to execute a registered task callback. The handler
  /// should execute the appropriate callback function based on the task ID.
  ///
  /// [handler] The function to call when a task needs to be executed.
  ///           It receives the task ID and data, and should return a Future
  ///           that completes when the task execution is done.
  static void setMethodCallHandler(
    Future<dynamic> Function(MethodCall call) handler,
  ) {
    _channel.setMethodCallHandler(handler);
  }

  /// Removes the method call handler.
  ///
  /// This method removes the current method call handler, preventing
  /// further callbacks from the native Android side.
  static void removeMethodCallHandler() {
    _channel.setMethodCallHandler(null);
  }

  /// Checks if the native Android side is available and responsive.
  ///
  /// This method performs a simple ping to verify that the native
  /// Android side is properly initialized and can respond to method calls.
  ///
  /// Returns true if the native side is responsive, false otherwise.
  static Future<bool> isNativeSideAvailable() async {
    try {
      await _channel.invokeMethod('ping');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Gets the version of the native Android implementation.
  ///
  /// This method retrieves the version string from the native Android side,
  /// which can be useful for debugging and compatibility checking.
  ///
  /// Returns the version string, or null if unavailable.
  static Future<String?> getNativeVersion() async {
    try {
      final result = await _channel.invokeMethod('getVersion');
      return result as String?;
    } catch (e) {
      return null;
    }
  }

  /// Gets detailed information about the native Android implementation.
  ///
  /// This method retrieves comprehensive information about the native
  /// Android side, including version, capabilities, and system status.
  ///
  /// Returns a map containing the native implementation details.
  static Future<Map<String, dynamic>> getNativeInfo() async {
    try {
      final result = await _channel.invokeMethod('getInfo');
      return Map<String, dynamic>.from(result as Map);
    } on PlatformException catch (e) {
      throw NativeOperationException(
        'getNativeInfo',
        e.message ?? 'Unknown error',
      );
    }
  }
}
