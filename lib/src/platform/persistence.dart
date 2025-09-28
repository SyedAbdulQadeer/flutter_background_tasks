import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exceptions.dart';
import '../models/task_options.dart';

/// Handles local persistence of scheduled task information.
///
/// This class manages the storage and retrieval of task information using
/// SharedPreferences. It provides a simple key-value store for tracking
/// which tasks are scheduled, their configurations, and execution history.
class TaskPersistence {
  static const String _tasksKey = 'android_background_tasks';
  static const String _taskPrefix = 'task_';
  static const String _lastCleanupKey = 'last_cleanup';

  /// Saves a scheduled task to local storage.
  ///
  /// This method stores the task information in SharedPreferences so that
  /// it can be retrieved later, even after app restarts. The task data
  /// is serialized as JSON before storage.
  ///
  /// [taskInfo] The task information to save.
  ///
  /// Throws [PersistenceException] if saving fails.
  static Future<void> saveTask(ScheduledTaskInfo taskInfo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final taskKey = '$_taskPrefix${taskInfo.id}';
      final taskJson = taskInfo.toMap();
      final success = await prefs.setString(taskKey, jsonEncode(taskJson));

      if (!success) {
        throw const PersistenceException(
          'save task',
          'Failed to write to SharedPreferences',
        );
      }

      // Update the tasks list
      await _updateTasksList(taskInfo.id, true);
    } catch (e) {
      if (e is PersistenceException) rethrow;
      throw PersistenceException('save task', e.toString());
    }
  }

  /// Loads a scheduled task from local storage.
  ///
  /// This method retrieves the task information for the specified task ID
  /// from SharedPreferences and deserializes it back to a ScheduledTaskInfo object.
  ///
  /// [taskId] The unique identifier of the task to load.
  ///
  /// Returns the ScheduledTaskInfo if found, null otherwise.
  ///
  /// Throws [PersistenceException] if loading fails.
  static Future<ScheduledTaskInfo?> loadTask(String taskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final taskKey = '$_taskPrefix$taskId';
      final taskJson = prefs.getString(taskKey);

      if (taskJson == null) return null;

      final taskMap = jsonDecode(taskJson) as Map<String, dynamic>;
      return ScheduledTaskInfo.fromMap(taskMap);
    } catch (e) {
      if (e is PersistenceException) rethrow;
      throw PersistenceException('load task', e.toString());
    }
  }

  /// Loads all scheduled tasks from local storage.
  ///
  /// This method retrieves all task information stored in SharedPreferences
  /// and returns them as a list of ScheduledTaskInfo objects.
  ///
  /// Returns a list of all stored ScheduledTaskInfo objects.
  ///
  /// Throws [PersistenceException] if loading fails.
  static Future<List<ScheduledTaskInfo>> loadAllTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksList = prefs.getStringList(_tasksKey) ?? <String>[];
      final tasks = <ScheduledTaskInfo>[];

      for (final taskId in tasksList) {
        final task = await loadTask(taskId);
        if (task != null) {
          tasks.add(task);
        }
      }

      return tasks;
    } catch (e) {
      if (e is PersistenceException) rethrow;
      throw PersistenceException('load all tasks', e.toString());
    }
  }

  /// Removes a scheduled task from local storage.
  ///
  /// This method deletes the task information for the specified task ID
  /// from SharedPreferences, including both the individual task data and
  /// its entry in the tasks list.
  ///
  /// [taskId] The unique identifier of the task to remove.
  ///
  /// Throws [PersistenceException] if removal fails.
  static Future<void> removeTask(String taskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final taskKey = '$_taskPrefix$taskId';

      // Remove the individual task data
      await prefs.remove(taskKey);

      // Update the tasks list
      await _updateTasksList(taskId, false);
    } catch (e) {
      if (e is PersistenceException) rethrow;
      throw PersistenceException('remove task', e.toString());
    }
  }

  /// Clears all scheduled tasks from local storage.
  ///
  /// This method removes all task information from SharedPreferences,
  /// effectively clearing the entire task database. Use with caution.
  ///
  /// Throws [PersistenceException] if clearing fails.
  static Future<void> clearAllTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksList = prefs.getStringList(_tasksKey) ?? <String>[];

      // Remove all individual task data
      for (final taskId in tasksList) {
        final taskKey = '$_taskPrefix$taskId';
        await prefs.remove(taskKey);
      }

      // Clear the tasks list
      await prefs.remove(_tasksKey);
    } catch (e) {
      if (e is PersistenceException) rethrow;
      throw PersistenceException('clear all tasks', e.toString());
    }
  }

  /// Updates the execution count for a task.
  ///
  /// This method increments the execution count and updates the last
  /// executed timestamp for the specified task.
  ///
  /// [taskId] The unique identifier of the task to update.
  ///
  /// Throws [PersistenceException] if update fails.
  static Future<void> updateTaskExecution(String taskId) async {
    try {
      final task = await loadTask(taskId);
      if (task == null) return;

      final updatedTask = ScheduledTaskInfo(
        id: task.id,
        options: task.options,
        isActive: task.isActive,
        lastExecuted: DateTime.now(),
        executionCount: task.executionCount + 1,
        failureCount: task.failureCount,
        scheduledAt: task.scheduledAt,
      );

      await saveTask(updatedTask);
    } catch (e) {
      if (e is PersistenceException) rethrow;
      throw PersistenceException('update task execution', e.toString());
    }
  }

  /// Updates the failure count for a task.
  ///
  /// This method increments the failure count for the specified task,
  /// which is used for retry logic and failure tracking.
  ///
  /// [taskId] The unique identifier of the task to update.
  ///
  /// Throws [PersistenceException] if update fails.
  static Future<void> updateTaskFailure(String taskId) async {
    try {
      final task = await loadTask(taskId);
      if (task == null) return;

      final updatedTask = ScheduledTaskInfo(
        id: task.id,
        options: task.options,
        isActive: task.isActive,
        lastExecuted: task.lastExecuted,
        executionCount: task.executionCount,
        failureCount: task.failureCount + 1,
        scheduledAt: task.scheduledAt,
      );

      await saveTask(updatedTask);
    } catch (e) {
      if (e is PersistenceException) rethrow;
      throw PersistenceException('update task failure', e.toString());
    }
  }

  /// Updates the active status of a task.
  ///
  /// This method updates whether a task is currently active and scheduled.
  /// This is useful when tasks are cancelled or when their status changes.
  ///
  /// [taskId] The unique identifier of the task to update.
  /// [isActive] Whether the task is currently active.
  ///
  /// Throws [PersistenceException] if update fails.
  static Future<void> updateTaskStatus(String taskId, bool isActive) async {
    try {
      final task = await loadTask(taskId);
      if (task == null) return;

      final updatedTask = ScheduledTaskInfo(
        id: task.id,
        options: task.options,
        isActive: isActive,
        lastExecuted: task.lastExecuted,
        executionCount: task.executionCount,
        failureCount: task.failureCount,
        scheduledAt: task.scheduledAt,
      );

      await saveTask(updatedTask);
    } catch (e) {
      if (e is PersistenceException) rethrow;
      throw PersistenceException('update task status', e.toString());
    }
  }

  /// Performs cleanup of old or invalid task data.
  ///
  /// This method removes tasks that are no longer valid or have been
  /// inactive for too long. It helps keep the storage clean and prevents
  /// accumulation of stale data.
  ///
  /// [maxAge] The maximum age in days for tasks to be considered valid.
  ///
  /// Throws [PersistenceException] if cleanup fails.
  static Future<void> cleanupOldTasks({int maxAge = 30}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCleanup = prefs.getInt(_lastCleanupKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Only run cleanup once per day
      if (now - lastCleanup < 24 * 60 * 60 * 1000) return;

      final tasks = await loadAllTasks();
      final cutoffDate = DateTime.now().subtract(Duration(days: maxAge));
      final tasksToRemove = <String>[];

      for (final task in tasks) {
        if (!task.isActive &&
            (task.lastExecuted == null ||
                task.lastExecuted!.isBefore(cutoffDate))) {
          tasksToRemove.add(task.id);
        }
      }

      for (final taskId in tasksToRemove) {
        await removeTask(taskId);
      }

      // Update last cleanup time
      await prefs.setInt(_lastCleanupKey, now);
    } catch (e) {
      if (e is PersistenceException) rethrow;
      throw PersistenceException('cleanup old tasks', e.toString());
    }
  }

  /// Gets storage statistics for debugging purposes.
  ///
  /// This method returns information about the current state of the
  /// task storage, including counts and sizes.
  ///
  /// Returns a map containing storage statistics.
  static Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasks = await loadAllTasks();

      int activeCount = 0;
      int inactiveCount = 0;
      int totalExecutions = 0;
      int totalFailures = 0;

      for (final task in tasks) {
        if (task.isActive) {
          activeCount++;
        } else {
          inactiveCount++;
        }
        totalExecutions += task.executionCount;
        totalFailures += task.failureCount;
      }

      return {
        'totalTasks': tasks.length,
        'activeTasks': activeCount,
        'inactiveTasks': inactiveCount,
        'totalExecutions': totalExecutions,
        'totalFailures': totalFailures,
        'lastCleanup': prefs.getInt(_lastCleanupKey),
      };
    } catch (e) {
      throw PersistenceException('get storage stats', e.toString());
    }
  }

  /// Updates the tasks list in SharedPreferences.
  ///
  /// This is a helper method that maintains the list of task IDs
  /// in SharedPreferences for efficient iteration.
  ///
  /// [taskId] The task ID to add or remove.
  /// [add] Whether to add (true) or remove (false) the task ID.
  static Future<void> _updateTasksList(String taskId, bool add) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksList = prefs.getStringList(_tasksKey) ?? <String>[];

    if (add) {
      if (!tasksList.contains(taskId)) {
        tasksList.add(taskId);
      }
    } else {
      tasksList.remove(taskId);
    }

    await prefs.setStringList(_tasksKey, tasksList);
  }
}
