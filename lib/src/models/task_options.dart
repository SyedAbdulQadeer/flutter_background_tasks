import 'dart:convert';
import 'exceptions.dart';

/// Configuration options for scheduling background tasks.
///
/// This class encapsulates all the parameters needed to schedule a background task,
/// including timing, constraints, and retry behavior. It provides validation to
/// ensure the options are compatible with Android's WorkManager and AlarmManager.
class TaskOptions {
  /// Unique identifier for the task.
  ///
  /// This ID must be unique across all tasks and is used to:
  /// - Cancel the task later
  /// - Track task state in persistence
  /// - Identify the task in native Android code
  final String id;

  /// Whether this is a periodic (repeating) task or one-time task.
  ///
  /// Periodic tasks use WorkManager and have a minimum frequency of 15 minutes.
  /// One-time tasks can use either WorkManager or AlarmManager depending on timing.
  final bool periodic;

  /// Frequency for periodic tasks.
  ///
  /// Required when [periodic] is true. Must be at least 15 minutes for WorkManager
  /// compatibility. For one-time tasks, this is ignored.
  final Duration? frequency;

  /// Initial delay before the first execution.
  ///
  /// For periodic tasks, this is the delay before the first run, after which
  /// the task will repeat at the specified frequency.
  /// For one-time tasks, this is the delay before the single execution.
  final Duration initialDelay;

  /// Whether the task requires the device to be charging.
  ///
  /// This constraint helps preserve battery life by only running tasks
  /// when the device is plugged in. Useful for heavy operations like
  /// data synchronization or large file processing.
  final bool requiresCharging;

  /// Whether the task requires a WiFi connection.
  ///
  /// This constraint ensures tasks only run when connected to WiFi,
  /// preventing mobile data usage for operations that require internet access.
  final bool requiresWifi;

  /// Whether the task should retry on failure with exponential backoff.
  ///
  /// When enabled, failed tasks will be retried with increasing delays
  /// (1s, 2s, 4s, 8s, etc.) up to a maximum number of attempts.
  final bool retryOnFail;

  /// Maximum number of retry attempts when [retryOnFail] is true.
  ///
  /// After this many attempts, the task will be marked as permanently failed.
  /// Defaults to 5 attempts if not specified.
  final int maxRetryAttempts;

  /// Additional data to pass to the task callback.
  ///
  /// This data will be serialized and passed to the native Android side,
  /// then made available to the task callback function.
  final Map<String, dynamic>? data;

  /// Creates a new TaskOptions instance.
  ///
  /// Throws [InvalidTaskOptionsException] if the options are invalid.
  const TaskOptions({
    required this.id,
    this.periodic = false,
    this.frequency,
    this.initialDelay = Duration.zero,
    this.requiresCharging = false,
    this.requiresWifi = false,
    this.retryOnFail = true,
    this.maxRetryAttempts = 5,
    this.data,
  }) : assert(
         !periodic || frequency != null,
         'Frequency must be provided for periodic tasks',
       );

  /// Validates the task options and throws appropriate exceptions if invalid.
  ///
  /// This method performs comprehensive validation to ensure the options
  /// are compatible with Android's background task systems.
  void validate() {
    // Validate ID
    if (id.trim().isEmpty) {
      throw const InvalidTaskOptionsException('Task ID cannot be empty');
    }

    // Validate periodic task requirements
    if (periodic) {
      if (frequency == null) {
        throw const InvalidTaskOptionsException(
          'Frequency must be provided for periodic tasks',
        );
      }

      // WorkManager requires minimum 15 minutes for periodic tasks
      if (frequency!.inMinutes < 15) {
        throw const InvalidFrequencyException();
      }
    }

    // Validate initial delay
    if (initialDelay.isNegative) {
      throw const InvalidTaskOptionsException(
        'Initial delay cannot be negative',
      );
    }

    // Validate retry attempts
    if (maxRetryAttempts < 0) {
      throw const InvalidTaskOptionsException(
        'Max retry attempts cannot be negative',
      );
    }

    // Validate data serialization
    if (data != null) {
      try {
        jsonEncode(data);
      } catch (e) {
        throw InvalidTaskOptionsException(
          'Task data must be JSON serializable: $e',
        );
      }
    }
  }

  /// Creates a copy of this TaskOptions with the given fields replaced.
  ///
  /// This is useful for creating variations of task options or updating
  /// specific parameters while keeping others unchanged.
  TaskOptions copyWith({
    String? id,
    bool? periodic,
    Duration? frequency,
    Duration? initialDelay,
    bool? requiresCharging,
    bool? requiresWifi,
    bool? retryOnFail,
    int? maxRetryAttempts,
    Map<String, dynamic>? data,
  }) {
    return TaskOptions(
      id: id ?? this.id,
      periodic: periodic ?? this.periodic,
      frequency: frequency ?? this.frequency,
      initialDelay: initialDelay ?? this.initialDelay,
      requiresCharging: requiresCharging ?? this.requiresCharging,
      requiresWifi: requiresWifi ?? this.requiresWifi,
      retryOnFail: retryOnFail ?? this.retryOnFail,
      maxRetryAttempts: maxRetryAttempts ?? this.maxRetryAttempts,
      data: data ?? this.data,
    );
  }

  /// Converts this TaskOptions to a Map for serialization.
  ///
  /// This is used when communicating with the native Android side
  /// and for local persistence of task configurations.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'periodic': periodic,
      'frequency': frequency?.inMilliseconds,
      'initialDelay': initialDelay.inMilliseconds,
      'requiresCharging': requiresCharging,
      'requiresWifi': requiresWifi,
      'retryOnFail': retryOnFail,
      'maxRetryAttempts': maxRetryAttempts,
      'data': data,
    };
  }

  /// Creates a TaskOptions from a Map (deserialization).
  ///
  /// This is used when loading task configurations from persistence
  /// or when receiving data from the native Android side.
  factory TaskOptions.fromMap(Map<String, dynamic> map) {
    return TaskOptions(
      id: map['id'] as String,
      periodic: map['periodic'] as bool? ?? false,
      frequency: map['frequency'] != null
          ? Duration(milliseconds: map['frequency'] as int)
          : null,
      initialDelay: Duration(milliseconds: map['initialDelay'] as int? ?? 0),
      requiresCharging: map['requiresCharging'] as bool? ?? false,
      requiresWifi: map['requiresWifi'] as bool? ?? false,
      retryOnFail: map['retryOnFail'] as bool? ?? true,
      maxRetryAttempts: map['maxRetryAttempts'] as int? ?? 5,
      data: map['data'] as Map<String, dynamic>?,
    );
  }

  /// Converts this TaskOptions to JSON string.
  String toJson() => jsonEncode(toMap());

  /// Creates a TaskOptions from JSON string.
  factory TaskOptions.fromJson(String source) =>
      TaskOptions.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TaskOptions &&
        other.id == id &&
        other.periodic == periodic &&
        other.frequency == frequency &&
        other.initialDelay == initialDelay &&
        other.requiresCharging == requiresCharging &&
        other.requiresWifi == requiresWifi &&
        other.retryOnFail == retryOnFail &&
        other.maxRetryAttempts == maxRetryAttempts &&
        _mapEquals(other.data, data);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      periodic,
      frequency,
      initialDelay,
      requiresCharging,
      requiresWifi,
      retryOnFail,
      maxRetryAttempts,
      data,
    );
  }

  @override
  String toString() {
    return 'TaskOptions(id: $id, periodic: $periodic, frequency: $frequency, '
        'initialDelay: $initialDelay, requiresCharging: $requiresCharging, '
        'requiresWifi: $requiresWifi, retryOnFail: $retryOnFail, '
        'maxRetryAttempts: $maxRetryAttempts, data: $data)';
  }

  /// Helper method to compare two maps for equality.
  bool _mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null) return b == null;
    if (b == null) return false;
    if (a.length != b.length) return false;

    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}

/// Callback function type for background task execution.
///
/// This function will be called when the background task is executed.
/// It receives the task ID and any additional data that was provided
/// when scheduling the task.
///
/// The function should return a Future that completes when the task is done.
/// If the task fails, the Future should complete with an error.
typedef BackgroundTaskCallback =
    Future<void> Function(String taskId, Map<String, dynamic>? data);

/// Information about a scheduled task.
///
/// This class represents a task that has been scheduled and provides
/// information about its current state and configuration.
class ScheduledTaskInfo {
  /// The unique identifier of the task.
  final String id;

  /// The task options used when scheduling.
  final TaskOptions options;

  /// Whether the task is currently scheduled and active.
  final bool isActive;

  /// Timestamp when the task was last executed.
  final DateTime? lastExecuted;

  /// Number of times the task has been executed.
  final int executionCount;

  /// Number of times the task has failed.
  final int failureCount;

  /// Timestamp when the task was scheduled.
  final DateTime scheduledAt;

  const ScheduledTaskInfo({
    required this.id,
    required this.options,
    required this.isActive,
    this.lastExecuted,
    required this.executionCount,
    required this.failureCount,
    required this.scheduledAt,
  });

  /// Creates a ScheduledTaskInfo from a Map (deserialization).
  factory ScheduledTaskInfo.fromMap(Map<String, dynamic> map) {
    return ScheduledTaskInfo(
      id: map['id'] as String,
      options: TaskOptions.fromMap(map['options'] as Map<String, dynamic>),
      isActive: map['isActive'] as bool,
      lastExecuted: map['lastExecuted'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastExecuted'] as int)
          : null,
      executionCount: map['executionCount'] as int,
      failureCount: map['failureCount'] as int,
      scheduledAt: DateTime.fromMillisecondsSinceEpoch(
        map['scheduledAt'] as int,
      ),
    );
  }

  /// Converts this ScheduledTaskInfo to a Map for serialization.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'options': options.toMap(),
      'isActive': isActive,
      'lastExecuted': lastExecuted?.millisecondsSinceEpoch,
      'executionCount': executionCount,
      'failureCount': failureCount,
      'scheduledAt': scheduledAt.millisecondsSinceEpoch,
    };
  }

  @override
  String toString() {
    return 'ScheduledTaskInfo(id: $id, isActive: $isActive, '
        'lastExecuted: $lastExecuted, executionCount: $executionCount, '
        'failureCount: $failureCount, scheduledAt: $scheduledAt)';
  }
}
