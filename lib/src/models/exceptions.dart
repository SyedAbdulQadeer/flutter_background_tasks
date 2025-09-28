/// Custom exceptions for the Android Background Task Manager package.
///
/// These exceptions provide clear, descriptive error messages to help developers
/// understand what went wrong and how to fix it.

/// Base exception class for all Android Background Task Manager errors.
abstract class AndroidBackgroundTaskException implements Exception {
  /// The error message describing what went wrong.
  final String message;

  /// Optional additional context about the error.
  final String? context;

  const AndroidBackgroundTaskException(this.message, [this.context]);

  @override
  String toString() => context != null
      ? 'AndroidBackgroundTaskException: $message\nContext: $context'
      : 'AndroidBackgroundTaskException: $message';
}

/// Thrown when attempting to register a task with an ID that already exists.
///
/// This prevents duplicate task registrations which could lead to unexpected
/// behavior or resource conflicts.
class DuplicateTaskIdException extends AndroidBackgroundTaskException {
  const DuplicateTaskIdException(String taskId)
    : super(
        'Task with ID "$taskId" is already registered. '
        'Please use a unique ID or cancel the existing task first.',
      );
}

/// Thrown when attempting to schedule a task that hasn't been registered yet.
///
/// All tasks must be registered before they can be scheduled to ensure
/// proper callback handling and resource management.
class TaskNotRegisteredException extends AndroidBackgroundTaskException {
  const TaskNotRegisteredException(String taskId)
    : super(
        'Task with ID "$taskId" has not been registered. '
        'Please register the task first using registerTask().',
      );
}

/// Thrown when task options contain invalid configuration values.
///
/// This includes cases like negative durations, invalid frequencies, or
/// conflicting constraint combinations.
class InvalidTaskOptionsException extends AndroidBackgroundTaskException {
  const InvalidTaskOptionsException(String reason)
    : super('Invalid task options: $reason');
}

/// Thrown when the minimum frequency requirement for periodic tasks is not met.
///
/// WorkManager requires periodic tasks to have a minimum interval of 15 minutes
/// to prevent battery drain and ensure system stability.
class InvalidFrequencyException extends AndroidBackgroundTaskException {
  const InvalidFrequencyException()
    : super(
        'Periodic tasks must have a frequency of at least 15 minutes. '
        'This is a WorkManager requirement to prevent battery drain.',
      );
}

/// Thrown when there's a conflict in task scheduling.
///
/// This can occur when trying to schedule overlapping tasks or when
/// system resources are insufficient.
class TaskSchedulingConflictException extends AndroidBackgroundTaskException {
  const TaskSchedulingConflictException(String reason)
    : super('Task scheduling conflict: $reason');
}

/// Thrown when the Android Background Task Manager is not properly initialized.
///
/// The manager must be initialized before any operations can be performed
/// to ensure proper setup of native communication channels.
class NotInitializedException extends AndroidBackgroundTaskException {
  const NotInitializedException()
    : super(
        'AndroidBackgroundTaskManager has not been initialized. '
        'Please call AndroidBackgroundTaskManager.initialize() first.',
      );
}

/// Thrown when a native Android operation fails.
///
/// This wraps native Android errors and provides context about what
/// operation failed on the Android side.
class NativeOperationException extends AndroidBackgroundTaskException {
  const NativeOperationException(String operation, String nativeError)
    : super('Native Android operation failed: $operation', nativeError);
}

/// Thrown when there's an issue with local persistence.
///
/// This can occur when SharedPreferences operations fail or when
/// there are issues with task state serialization/deserialization.
class PersistenceException extends AndroidBackgroundTaskException {
  const PersistenceException(String operation, String reason)
    : super('Failed to $operation: $reason');
}
