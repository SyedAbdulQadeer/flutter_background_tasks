import 'package:flutter_test/flutter_test.dart';
import 'package:android_background_task_manager/android_background_task_manager.dart';

void main() {
  group('TaskOptions', () {
    test('should create valid one-time task options', () {
      final options = TaskOptions(
        id: 'test_task',
        periodic: false,
        initialDelay: const Duration(seconds: 30),
        requiresCharging: true,
        requiresWifi: false,
        retryOnFail: true,
        maxRetryAttempts: 3,
        data: {'key': 'value'},
      );

      expect(options.id, 'test_task');
      expect(options.periodic, false);
      expect(options.frequency, null);
      expect(options.initialDelay, const Duration(seconds: 30));
      expect(options.requiresCharging, true);
      expect(options.requiresWifi, false);
      expect(options.retryOnFail, true);
      expect(options.maxRetryAttempts, 3);
      expect(options.data, {'key': 'value'});
    });

    test('should create valid periodic task options', () {
      final options = TaskOptions(
        id: 'periodic_task',
        periodic: true,
        frequency: const Duration(minutes: 30),
        initialDelay: const Duration(minutes: 5),
        requiresCharging: false,
        requiresWifi: true,
        retryOnFail: false,
        maxRetryAttempts: 1,
      );

      expect(options.id, 'periodic_task');
      expect(options.periodic, true);
      expect(options.frequency, const Duration(minutes: 30));
      expect(options.initialDelay, const Duration(minutes: 5));
      expect(options.requiresCharging, false);
      expect(options.requiresWifi, true);
      expect(options.retryOnFail, false);
      expect(options.maxRetryAttempts, 1);
      expect(options.data, null);
    });

    test('should validate successfully with valid options', () {
      final options = TaskOptions(
        id: 'valid_task',
        periodic: true,
        frequency: const Duration(minutes: 20),
        initialDelay: const Duration(seconds: 10),
        requiresCharging: false,
        requiresWifi: false,
        retryOnFail: true,
        maxRetryAttempts: 5,
        data: {'test': 'data'},
      );

      expect(() => options.validate(), returnsNormally);
    });

    test('should throw InvalidTaskOptionsException for empty task ID', () {
      final options = TaskOptions(id: '', periodic: false);

      expect(
        () => options.validate(),
        throwsA(isA<InvalidTaskOptionsException>()),
      );
    });

    test(
      'should throw InvalidTaskOptionsException for whitespace-only task ID',
      () {
        final options = TaskOptions(id: '   ', periodic: false);

        expect(
          () => options.validate(),
          throwsA(isA<InvalidTaskOptionsException>()),
        );
      },
    );

    test(
      'should throw InvalidTaskOptionsException for periodic task without frequency',
      () {
        final options = TaskOptions(
          id: 'periodic_task',
          periodic: true,
          // frequency is null
        );

        expect(
          () => options.validate(),
          throwsA(isA<InvalidTaskOptionsException>()),
        );
      },
    );

    test(
      'should throw InvalidFrequencyException for frequency less than 15 minutes',
      () {
        final options = TaskOptions(
          id: 'periodic_task',
          periodic: true,
          frequency: const Duration(minutes: 10), // Less than 15 minutes
        );

        expect(
          () => options.validate(),
          throwsA(isA<InvalidFrequencyException>()),
        );
      },
    );

    test(
      'should throw InvalidTaskOptionsException for negative initial delay',
      () {
        final options = TaskOptions(
          id: 'test_task',
          periodic: false,
          initialDelay: const Duration(seconds: -10),
        );

        expect(
          () => options.validate(),
          throwsA(isA<InvalidTaskOptionsException>()),
        );
      },
    );

    test(
      'should throw InvalidTaskOptionsException for negative max retry attempts',
      () {
        final options = TaskOptions(
          id: 'test_task',
          periodic: false,
          maxRetryAttempts: -1,
        );

        expect(
          () => options.validate(),
          throwsA(isA<InvalidTaskOptionsException>()),
        );
      },
    );

    test(
      'should throw InvalidTaskOptionsException for non-serializable data',
      () {
        final options = TaskOptions(
          id: 'test_task',
          periodic: false,
          data: {'function': () {}}, // Functions are not JSON serializable
        );

        expect(
          () => options.validate(),
          throwsA(isA<InvalidTaskOptionsException>()),
        );
      },
    );

    test('should create copy with updated fields', () {
      final original = TaskOptions(
        id: 'original_task',
        periodic: false,
        initialDelay: const Duration(seconds: 30),
        requiresCharging: false,
        requiresWifi: false,
        retryOnFail: true,
        maxRetryAttempts: 3,
      );

      final updated = original.copyWith(
        id: 'updated_task',
        requiresCharging: true,
        maxRetryAttempts: 5,
      );

      expect(updated.id, 'updated_task');
      expect(updated.periodic, false);
      expect(updated.initialDelay, const Duration(seconds: 30));
      expect(updated.requiresCharging, true);
      expect(updated.requiresWifi, false);
      expect(updated.retryOnFail, true);
      expect(updated.maxRetryAttempts, 5);
    });

    test('should serialize to map correctly', () {
      final options = TaskOptions(
        id: 'test_task',
        periodic: true,
        frequency: const Duration(minutes: 30),
        initialDelay: const Duration(seconds: 10),
        requiresCharging: true,
        requiresWifi: false,
        retryOnFail: true,
        maxRetryAttempts: 3,
        data: {'key': 'value'},
      );

      final map = options.toMap();

      expect(map['id'], 'test_task');
      expect(map['periodic'], true);
      expect(map['frequency'], 30 * 60 * 1000); // 30 minutes in milliseconds
      expect(map['initialDelay'], 10 * 1000); // 10 seconds in milliseconds
      expect(map['requiresCharging'], true);
      expect(map['requiresWifi'], false);
      expect(map['retryOnFail'], true);
      expect(map['maxRetryAttempts'], 3);
      expect(map['data'], {'key': 'value'});
    });

    test('should deserialize from map correctly', () {
      final map = {
        'id': 'test_task',
        'periodic': true,
        'frequency': 30 * 60 * 1000, // 30 minutes in milliseconds
        'initialDelay': 10 * 1000, // 10 seconds in milliseconds
        'requiresCharging': true,
        'requiresWifi': false,
        'retryOnFail': true,
        'maxRetryAttempts': 3,
        'data': {'key': 'value'},
      };

      final options = TaskOptions.fromMap(map);

      expect(options.id, 'test_task');
      expect(options.periodic, true);
      expect(options.frequency, const Duration(minutes: 30));
      expect(options.initialDelay, const Duration(seconds: 10));
      expect(options.requiresCharging, true);
      expect(options.requiresWifi, false);
      expect(options.retryOnFail, true);
      expect(options.maxRetryAttempts, 3);
      expect(options.data, {'key': 'value'});
    });

    test('should serialize to JSON and back correctly', () {
      final original = TaskOptions(
        id: 'json_test',
        periodic: true,
        frequency: const Duration(minutes: 45),
        initialDelay: const Duration(seconds: 20),
        requiresCharging: false,
        requiresWifi: true,
        retryOnFail: true,
        maxRetryAttempts: 4,
        data: {'json': 'test', 'number': 42},
      );

      final json = original.toJson();
      final restored = TaskOptions.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.periodic, original.periodic);
      expect(restored.frequency, original.frequency);
      expect(restored.initialDelay, original.initialDelay);
      expect(restored.requiresCharging, original.requiresCharging);
      expect(restored.requiresWifi, original.requiresWifi);
      expect(restored.retryOnFail, original.retryOnFail);
      expect(restored.maxRetryAttempts, original.maxRetryAttempts);
      expect(restored.data, original.data);
    });

    test('should implement equality correctly', () {
      final options1 = TaskOptions(
        id: 'equality_test',
        periodic: true,
        frequency: const Duration(minutes: 30),
        initialDelay: const Duration(seconds: 10),
        requiresCharging: true,
        requiresWifi: false,
        retryOnFail: true,
        maxRetryAttempts: 3,
        data: {'key': 'value'},
      );

      final options2 = TaskOptions(
        id: 'equality_test',
        periodic: true,
        frequency: const Duration(minutes: 30),
        initialDelay: const Duration(seconds: 10),
        requiresCharging: true,
        requiresWifi: false,
        retryOnFail: true,
        maxRetryAttempts: 3,
        data: {'key': 'value'},
      );

      final options3 = TaskOptions(
        id: 'different_task',
        periodic: true,
        frequency: const Duration(minutes: 30),
        initialDelay: const Duration(seconds: 10),
        requiresCharging: true,
        requiresWifi: false,
        retryOnFail: true,
        maxRetryAttempts: 3,
        data: {'key': 'value'},
      );

      expect(options1, equals(options2));
      expect(options1, isNot(equals(options3)));
      expect(options1.hashCode, equals(options2.hashCode));
      expect(options1.hashCode, isNot(equals(options3.hashCode)));
    });

    test('should have correct string representation', () {
      final options = TaskOptions(
        id: 'string_test',
        periodic: true,
        frequency: const Duration(minutes: 30),
        initialDelay: const Duration(seconds: 10),
        requiresCharging: true,
        requiresWifi: false,
        retryOnFail: true,
        maxRetryAttempts: 3,
        data: {'key': 'value'},
      );

      final str = options.toString();
      expect(str, contains('string_test'));
      expect(str, contains('true')); // periodic
      expect(str, contains('0:30:00.000000')); // frequency
      expect(str, contains('0:00:10.000000')); // initialDelay
    });
  });

  group('ScheduledTaskInfo', () {
    test('should create valid scheduled task info', () {
      final options = TaskOptions(
        id: 'test_task',
        periodic: true,
        frequency: const Duration(minutes: 30),
      );

      final taskInfo = ScheduledTaskInfo(
        id: 'test_task',
        options: options,
        isActive: true,
        lastExecuted: DateTime(2023, 1, 1, 12, 0, 0),
        executionCount: 5,
        failureCount: 1,
        scheduledAt: DateTime(2023, 1, 1, 10, 0, 0),
      );

      expect(taskInfo.id, 'test_task');
      expect(taskInfo.options, options);
      expect(taskInfo.isActive, true);
      expect(taskInfo.lastExecuted, DateTime(2023, 1, 1, 12, 0, 0));
      expect(taskInfo.executionCount, 5);
      expect(taskInfo.failureCount, 1);
      expect(taskInfo.scheduledAt, DateTime(2023, 1, 1, 10, 0, 0));
    });

    test('should serialize to map correctly', () {
      final options = TaskOptions(
        id: 'test_task',
        periodic: true,
        frequency: const Duration(minutes: 30),
      );

      final taskInfo = ScheduledTaskInfo(
        id: 'test_task',
        options: options,
        isActive: true,
        lastExecuted: DateTime(2023, 1, 1, 12, 0, 0),
        executionCount: 5,
        failureCount: 1,
        scheduledAt: DateTime(2023, 1, 1, 10, 0, 0),
      );

      final map = taskInfo.toMap();

      expect(map['id'], 'test_task');
      expect(map['isActive'], true);
      expect(
        map['lastExecuted'],
        DateTime(2023, 1, 1, 12, 0, 0).millisecondsSinceEpoch,
      );
      expect(map['executionCount'], 5);
      expect(map['failureCount'], 1);
      expect(
        map['scheduledAt'],
        DateTime(2023, 1, 1, 10, 0, 0).millisecondsSinceEpoch,
      );
      expect(map['options'], isA<Map<String, dynamic>>());
    });

    test('should deserialize from map correctly', () {
      final map = {
        'id': 'test_task',
        'options': {
          'id': 'test_task',
          'periodic': true,
          'frequency': 30 * 60 * 1000,
          'initialDelay': 0,
          'requiresCharging': false,
          'requiresWifi': false,
          'retryOnFail': true,
          'maxRetryAttempts': 5,
          'data': null,
        },
        'isActive': true,
        'lastExecuted': DateTime(2023, 1, 1, 12, 0, 0).millisecondsSinceEpoch,
        'executionCount': 5,
        'failureCount': 1,
        'scheduledAt': DateTime(2023, 1, 1, 10, 0, 0).millisecondsSinceEpoch,
      };

      final taskInfo = ScheduledTaskInfo.fromMap(map);

      expect(taskInfo.id, 'test_task');
      expect(taskInfo.isActive, true);
      expect(taskInfo.lastExecuted, DateTime(2023, 1, 1, 12, 0, 0));
      expect(taskInfo.executionCount, 5);
      expect(taskInfo.failureCount, 1);
      expect(taskInfo.scheduledAt, DateTime(2023, 1, 1, 10, 0, 0));
      expect(taskInfo.options.id, 'test_task');
      expect(taskInfo.options.periodic, true);
    });
  });
}
