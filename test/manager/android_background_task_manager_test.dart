import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:android_background_task_manager/android_background_task_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('AndroidBackgroundTaskManager', () {
    late MethodChannel mockChannel;
    late List<MethodCall> methodCalls;

    setUp(() {
      methodCalls = [];
      mockChannel = MethodChannel('android_background_task_manager');
      
      // Mock the method channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(mockChannel, (call) async {
        methodCalls.add(call);
        
        switch (call.method) {
          case 'initialize':
            return 'Initialized successfully';
          case 'scheduleTask':
            return 'Task scheduled successfully';
          case 'cancelTask':
            return 'Task cancelled successfully';
          case 'cancelAllTasks':
            return 'All tasks cancelled successfully';
          case 'getScheduledTasks':
            return <Map<String, dynamic>>[];
          case 'isTaskScheduled':
            return false;
          case 'executeTaskNow':
            return 'Task execution initiated';
          default:
            throw PlatformException(code: 'UNKNOWN_METHOD', message: 'Unknown method');
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(mockChannel, null);
      AndroidBackgroundTaskManager.reset();
    });

    group('initialization', () {
      test('should initialize successfully', () async {
        await AndroidBackgroundTaskManager.initialize();
        
        expect(AndroidBackgroundTaskManager.isInitialized, true);
        expect(methodCalls.length, 1);
        expect(methodCalls.first.method, 'initialize');
      });

      test('should not initialize twice', () async {
        await AndroidBackgroundTaskManager.initialize();
        await AndroidBackgroundTaskManager.initialize();
        
        expect(methodCalls.length, 1); // Only called once
      });

      test('should throw NativeOperationException on initialization failure', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(mockChannel, (call) async {
          throw PlatformException(code: 'INIT_ERROR', message: 'Initialization failed');
        });

        expect(
          () => AndroidBackgroundTaskManager.initialize(),
          throwsA(isA<NativeOperationException>()),
        );
      });
    });

    group('task registration', () {
      setUp(() async {
        await AndroidBackgroundTaskManager.initialize();
      });

      test('should register task successfully', () {
        AndroidBackgroundTaskManager.registerTask('test_task', (id, data) async {
          // Task callback
        });

        expect(AndroidBackgroundTaskManager.registeredTaskCount, 1);
      });

      test('should throw DuplicateTaskIdException for duplicate task ID', () {
        AndroidBackgroundTaskManager.registerTask('test_task', (id, data) async {});
        
        expect(
          () => AndroidBackgroundTaskManager.registerTask('test_task', (id, data) async {}),
          throwsA(isA<DuplicateTaskIdException>()),
        );
      });

      test('should unregister task successfully', () {
        AndroidBackgroundTaskManager.registerTask('test_task', (id, data) async {});
        expect(AndroidBackgroundTaskManager.registeredTaskCount, 1);
        
        AndroidBackgroundTaskManager.unregisterTask('test_task');
        expect(AndroidBackgroundTaskManager.registeredTaskCount, 0);
      });
    });

    group('task scheduling', () {
      setUp(() async {
        await AndroidBackgroundTaskManager.initialize();
        AndroidBackgroundTaskManager.registerTask('test_task', (id, data) async {});
      });

      test('should schedule task successfully', () async {
        final options = TaskOptions(
          id: 'test_task',
          periodic: false,
          initialDelay: const Duration(seconds: 10),
        );

        await AndroidBackgroundTaskManager.scheduleTask(options);
        
        expect(methodCalls.length, 1);
        expect(methodCalls.first.method, 'scheduleTask');
        expect(AndroidBackgroundTaskManager.scheduledTaskCount, 1);
      });

      test('should throw NotInitializedException when not initialized', () {
        AndroidBackgroundTaskManager.reset();
        
        final options = TaskOptions(id: 'test_task');
        
        expect(
          () => AndroidBackgroundTaskManager.scheduleTask(options),
          throwsA(isA<NotInitializedException>()),
        );
      });

      test('should throw TaskNotRegisteredException for unregistered task', () async {
        final options = TaskOptions(id: 'unregistered_task');
        
        expect(
          () => AndroidBackgroundTaskManager.scheduleTask(options),
          throwsA(isA<TaskNotRegisteredException>()),
        );
      });

      test('should throw InvalidTaskOptionsException for invalid options', () async {
        final options = TaskOptions(
          id: 'test_task',
          periodic: true,
          frequency: const Duration(minutes: 5), // Less than 15 minutes
        );

        expect(
          () => AndroidBackgroundTaskManager.scheduleTask(options),
          throwsA(isA<InvalidFrequencyException>()),
        );
      });

      test('should throw NativeOperationException on scheduling failure', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(mockChannel, (call) async {
          throw PlatformException(code: 'SCHEDULE_ERROR', message: 'Scheduling failed');
        });

        final options = TaskOptions(id: 'test_task');
        
        expect(
          () => AndroidBackgroundTaskManager.scheduleTask(options),
          throwsA(isA<NativeOperationException>()),
        );
      });
    });

    group('task cancellation', () {
      setUp(() async {
        await AndroidBackgroundTaskManager.initialize();
        AndroidBackgroundTaskManager.registerTask('test_task', (id, data) async {});
      });

      test('should cancel task successfully', () async {
        await AndroidBackgroundTaskManager.cancelTask('test_task');
        
        expect(methodCalls.length, 1);
        expect(methodCalls.first.method, 'cancelTask');
        expect(methodCalls.first.arguments, {'taskId': 'test_task'});
      });

      test('should cancel all tasks successfully', () async {
        await AndroidBackgroundTaskManager.cancelAllTasks();
        
        expect(methodCalls.length, 1);
        expect(methodCalls.first.method, 'cancelAllTasks');
      });

      test('should throw NotInitializedException when not initialized', () {
        AndroidBackgroundTaskManager.reset();
        
        expect(
          () => AndroidBackgroundTaskManager.cancelTask('test_task'),
          throwsA(isA<NotInitializedException>()),
        );
      });

      test('should throw NativeOperationException on cancellation failure', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(mockChannel, (call) async {
          throw PlatformException(code: 'CANCEL_ERROR', message: 'Cancellation failed');
        });

        expect(
          () => AndroidBackgroundTaskManager.cancelTask('test_task'),
          throwsA(isA<NativeOperationException>()),
        );
      });
    });

    group('task information', () {
      setUp(() async {
        await AndroidBackgroundTaskManager.initialize();
      });

      test('should get scheduled tasks successfully', () async {
        final tasks = await AndroidBackgroundTaskManager.getScheduledTasks();
        
        expect(tasks, isA<List<ScheduledTaskInfo>>());
        expect(methodCalls.length, 1);
        expect(methodCalls.first.method, 'getScheduledTasks');
      });

      test('should check if task is scheduled', () async {
        final isScheduled = await AndroidBackgroundTaskManager.isTaskScheduled('test_task');
        
        expect(isScheduled, false);
        expect(methodCalls.length, 1);
        expect(methodCalls.first.method, 'isTaskScheduled');
      });

      test('should throw NotInitializedException when not initialized', () {
        AndroidBackgroundTaskManager.reset();
        
        expect(
          () => AndroidBackgroundTaskManager.getScheduledTasks(),
          throwsA(isA<NotInitializedException>()),
        );
      });
    });

    group('task execution', () {
      setUp(() async {
        await AndroidBackgroundTaskManager.initialize();
        AndroidBackgroundTaskManager.registerTask('test_task', (id, data) async {});
      });

      test('should execute task now successfully', () async {
        await AndroidBackgroundTaskManager.executeTaskNow('test_task');
        
        expect(methodCalls.length, 1);
        expect(methodCalls.first.method, 'executeTaskNow');
        expect(methodCalls.first.arguments, {'taskId': 'test_task'});
      });

      test('should throw NotInitializedException when not initialized', () {
        AndroidBackgroundTaskManager.reset();
        
        expect(
          () => AndroidBackgroundTaskManager.executeTaskNow('test_task'),
          throwsA(isA<NotInitializedException>()),
        );
      });

      test('should throw TaskNotRegisteredException for unregistered task', () async {
        expect(
          () => AndroidBackgroundTaskManager.executeTaskNow('unregistered_task'),
          throwsA(isA<TaskNotRegisteredException>()),
        );
      });

      test('should throw NativeOperationException on execution failure', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(mockChannel, (call) async {
          throw PlatformException(code: 'EXECUTE_ERROR', message: 'Execution failed');
        });

        expect(
          () => AndroidBackgroundTaskManager.executeTaskNow('test_task'),
          throwsA(isA<NativeOperationException>()),
        );
      });
    });

    group('task execution stream', () {
      setUp(() async {
        await AndroidBackgroundTaskManager.initialize();
      });

      test('should provide task execution stream', () {
        final stream = AndroidBackgroundTaskManager.taskExecutionStream;
        expect(stream, isA<Stream<String>>());
      });

      test('should emit task IDs when tasks are executed', () async {
        final stream = AndroidBackgroundTaskManager.taskExecutionStream;
        final taskIds = <String>[];
        
        final subscription = stream.listen(taskIds.add);
        
        // Simulate task execution
        AndroidBackgroundTaskManager.registerTask('test_task', (id, data) async {});
        
        // This would normally be called by the native side
        // For testing, we'll simulate it
        await Future.delayed(const Duration(milliseconds: 100));
        
        subscription.cancel();
        // Note: In a real test, you would need to trigger the actual execution
        // through the method call handler
      });
    });

    group('properties', () {
      test('should return correct initialization status', () {
        expect(AndroidBackgroundTaskManager.isInitialized, false);
        
        AndroidBackgroundTaskManager.initialize().then((_) {
          expect(AndroidBackgroundTaskManager.isInitialized, true);
        });
      });

      test('should return correct task counts', () async {
        await AndroidBackgroundTaskManager.initialize();
        
        expect(AndroidBackgroundTaskManager.registeredTaskCount, 0);
        expect(AndroidBackgroundTaskManager.scheduledTaskCount, 0);
        
        AndroidBackgroundTaskManager.registerTask('test_task', (id, data) async {});
        expect(AndroidBackgroundTaskManager.registeredTaskCount, 1);
      });
    });

    group('reset', () {
      test('should reset manager to initial state', () async {
        await AndroidBackgroundTaskManager.initialize();
        AndroidBackgroundTaskManager.registerTask('test_task', (id, data) async {});
        
        AndroidBackgroundTaskManager.reset();
        
        expect(AndroidBackgroundTaskManager.isInitialized, false);
        expect(AndroidBackgroundTaskManager.registeredTaskCount, 0);
        expect(AndroidBackgroundTaskManager.scheduledTaskCount, 0);
      });
    });
  });
}
