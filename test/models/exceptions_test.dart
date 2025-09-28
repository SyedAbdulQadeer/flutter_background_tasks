import 'package:flutter_test/flutter_test.dart';
import 'package:android_background_task_manager/android_background_task_manager.dart';

void main() {
  group('AndroidBackgroundTaskException', () {
    test('should create exception with message only', () {
      const exception = InvalidTaskOptionsException('Test error message');
      
      expect(exception.message, 'Test error message');
      expect(exception.context, null);
      expect(exception.toString(), 'AndroidBackgroundTaskException: Test error message');
    });

    test('should create exception with message and context', () {
      const exception = NativeOperationException('Test operation', 'Test context');
      
      expect(exception.message, 'Test operation');
      expect(exception.context, 'Test context');
      expect(exception.toString(), contains('Test operation'));
      expect(exception.toString(), contains('Test context'));
    });
  });

  group('DuplicateTaskIdException', () {
    test('should create exception with task ID', () {
      const exception = DuplicateTaskIdException('test_task_id');
      
      expect(exception.message, contains('test_task_id'));
      expect(exception.message, contains('already registered'));
    });
  });

  group('TaskNotRegisteredException', () {
    test('should create exception with task ID', () {
      const exception = TaskNotRegisteredException('unregistered_task');
      
      expect(exception.message, contains('unregistered_task'));
      expect(exception.message, contains('not been registered'));
    });
  });

  group('InvalidTaskOptionsException', () {
    test('should create exception with reason', () {
      const exception = InvalidTaskOptionsException('Invalid frequency value');
      
      expect(exception.message, contains('Invalid frequency value'));
    });
  });

  group('InvalidFrequencyException', () {
    test('should create exception with WorkManager requirement message', () {
      const exception = InvalidFrequencyException();
      
      expect(exception.message, contains('15 minutes'));
      expect(exception.message, contains('WorkManager'));
    });
  });

  group('TaskSchedulingConflictException', () {
    test('should create exception with conflict reason', () {
      const exception = TaskSchedulingConflictException('Resource unavailable');
      
      expect(exception.message, contains('Resource unavailable'));
    });
  });

  group('NotInitializedException', () {
    test('should create exception with initialization message', () {
      const exception = NotInitializedException();
      
      expect(exception.message, contains('not been initialized'));
      expect(exception.message, contains('initialize()'));
    });
  });

  group('NativeOperationException', () {
    test('should create exception with operation and native error', () {
      const exception = NativeOperationException('scheduleTask', 'WorkManager error');
      
      expect(exception.message, contains('scheduleTask'));
      expect(exception.context, 'WorkManager error');
    });
  });

  group('PersistenceException', () {
    test('should create exception with operation and reason', () {
      const exception = PersistenceException('save task', 'Database locked');
      
      expect(exception.message, contains('save task'));
      expect(exception.context, 'Database locked');
    });
  });

  group('Exception inheritance', () {
    test('all exceptions should be instances of AndroidBackgroundTaskException', () {
      expect(const DuplicateTaskIdException('test'), isA<AndroidBackgroundTaskException>());
      expect(const TaskNotRegisteredException('test'), isA<AndroidBackgroundTaskException>());
      expect(const InvalidTaskOptionsException('test'), isA<AndroidBackgroundTaskException>());
      expect(const InvalidFrequencyException(), isA<AndroidBackgroundTaskException>());
      expect(const TaskSchedulingConflictException('test'), isA<AndroidBackgroundTaskException>());
      expect(const NotInitializedException(), isA<AndroidBackgroundTaskException>());
      expect(const NativeOperationException('test', 'test'), isA<AndroidBackgroundTaskException>());
      expect(const PersistenceException('test', 'test'), isA<AndroidBackgroundTaskException>());
    });

    test('all exceptions should be instances of Exception', () {
      expect(const DuplicateTaskIdException('test'), isA<Exception>());
      expect(const TaskNotRegisteredException('test'), isA<Exception>());
      expect(const InvalidTaskOptionsException('test'), isA<Exception>());
      expect(const InvalidFrequencyException(), isA<Exception>());
      expect(const TaskSchedulingConflictException('test'), isA<Exception>());
      expect(const NotInitializedException(), isA<Exception>());
      expect(const NativeOperationException('test', 'test'), isA<Exception>());
      expect(const PersistenceException('test', 'test'), isA<Exception>());
    });
  });

  group('Exception equality', () {
    test('exceptions with same message and context should be equal', () {
      const exception1 = NativeOperationException('test', 'context');
      const exception2 = NativeOperationException('test', 'context');
      
      expect(exception1, equals(exception2));
      expect(exception1.hashCode, equals(exception2.hashCode));
    });

    test('exceptions with different message should not be equal', () {
      const exception1 = NativeOperationException('test1', 'context');
      const exception2 = NativeOperationException('test2', 'context');
      
      expect(exception1, isNot(equals(exception2)));
    });

    test('exceptions with different context should not be equal', () {
      const exception1 = NativeOperationException('test', 'context1');
      const exception2 = NativeOperationException('test', 'context2');
      
      expect(exception1, isNot(equals(exception2)));
    });
  });
}
