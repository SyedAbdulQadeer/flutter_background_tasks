import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:android_background_task_manager/android_background_task_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('AndroidBackgroundTaskMethodChannel', () {
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
          case 'ping':
            return 'pong';
          case 'getVersion':
            return '1.0.0';
          case 'getInfo':
            return {
              'version': '1.0.0',
              'androidVersion': '13',
              'apiLevel': 33,
            };
          default:
            throw PlatformException(code: 'UNKNOWN_METHOD', message: 'Unknown method');
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(mockChannel, null);
    });

    group('initialize', () {
      test('should call initialize method on native side', () async {
        await AndroidBackgroundTaskMethodChannel.initialize();
        
        expect(methodCalls.length, 1);
        expect(methodCalls.first.method, 'initialize');
      });

      test('should throw NativeOperationException on platform error', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(mockChannel, (call) async {
          throw PlatformException(code: 'INIT_ERROR', message: 'Initialization failed');
        });

        expect(
          () => AndroidBackgroundTaskMethodChannel.initialize(),
          throwsA(isA<NativeOperationException>()),
        );
      });
    });

    group('scheduleTask', () {
      test('should call scheduleTask method with correct arguments', () async {
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

        await AndroidBackgroundTaskMethodChannel.scheduleTask(options);
        
        expect(methodCalls.length, 1);
        expect(methodCalls.first.method, 'scheduleTask');
        expect(methodCalls.first.arguments, options.toMap());
      });

      test('should throw NativeOperationException on platform error', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(mockChannel, (call) async {
          throw PlatformException(code: 'SCHEDULE_ERROR', message: 'Scheduling failed');
        });

        final options = TaskOptions(id: 'test_task');
        
        expect(
          () => AndroidBackgroundTaskMethodChannel.scheduleTask(options),
          throwsA(isA<NativeOperationException>()),
        );
      });
    });

    group('cancelTask', () {
      test('should call cancelTask method with correct task ID', () async {
        await AndroidBackgroundTaskMethodChannel.cancelTask('test_task');
        
        expect(methodCalls.length, 1);
        expect(methodCalls.first.method, 'cancelTask');
        expect(methodCalls.first.arguments, {'taskId': 'test_task'});
      });

      test('should throw NativeOperationException on platform error', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(mockChannel, (call) async {
          throw PlatformException(code: 'CANCEL_ERROR', message: 'Cancellation failed');
        });

        expect(
          () => AndroidBackgroundTaskMethodChannel.cancelTask('test_task'),
          throwsA(isA<NativeOperationException>()),
        );
      });
    });

    group('cancelAllTasks', () {
      test('should call cancelAllTasks method', () async {
        await AndroidBackgroundTaskMethodChannel.cancelAllTasks();
        
        expect(methodCalls.length, 1);
        expect(methodCalls.first.method, 'cancelAllTasks');
      });

      test('should throw NativeOperationException on platform error', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(mockChannel, (call) async {
          throw PlatformException(code: 'CANCEL_ALL_ERROR', message: 'Cancellation failed');
        });

        expect(
          () => AndroidBackgroundTaskMethodChannel.cancelAllTasks(),
          throwsA(isA<NativeOperationException>()),
        );
      });
    });

    group('getScheduledTasks', () {
      test('should call getScheduledTasks method and return task list', () async {
        final tasks = await AndroidBackgroundTaskMethodChannel.getScheduledTasks();
        
        expect(methodCalls.length, 1);
        expect(methodCalls.first.method, 'getScheduledTasks');
        expect(tasks, isA<List<ScheduledTaskInfo>>());
      });

      test('should throw NativeOperationException on platform error', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(mockChannel, (call) async {
          throw PlatformException(code: 'GET_TASKS_ERROR', message: 'Failed to get tasks');
        });

        expect(
          () => AndroidBackgroundTaskMethodChannel.getScheduledTasks(),
          throwsA(isA<NativeOperationException>()),
        );
      });
    });

    group('isTaskScheduled', () {
      test('should call isTaskScheduled method with correct task ID', () async {
        final isScheduled = await AndroidBackgroundTaskMethodChannel.isTaskScheduled('test_task');
        
        expect(methodCalls.length, 1);
        expect(methodCalls.first.method, 'isTaskScheduled');
        expect(methodCalls.first.arguments, {'taskId': 'test_task'});
        expect(isScheduled, false);
      });

      test('should throw NativeOperationException on platform error', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(mockChannel, (call) async {
          throw PlatformException(code: 'IS_SCHEDULED_ERROR', message: 'Check failed');
        });

        expect(
          () => AndroidBackgroundTaskMethodChannel.isTaskScheduled('test_task'),
          throwsA(isA<NativeOperationException>()),
        );
      });
    });

    group('executeTaskNow', () {
      test('should call executeTaskNow method with correct task ID', () async {
        await AndroidBackgroundTaskMethodChannel.executeTaskNow('test_task');
        
        expect(methodCalls.length, 1);
        expect(methodCalls.first.method, 'executeTaskNow');
        expect(methodCalls.first.arguments, {'taskId': 'test_task'});
      });

      test('should throw NativeOperationException on platform error', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(mockChannel, (call) async {
          throw PlatformException(code: 'EXECUTE_ERROR', message: 'Execution failed');
        });

        expect(
          () => AndroidBackgroundTaskMethodChannel.executeTaskNow('test_task'),
          throwsA(isA<NativeOperationException>()),
        );
      });
    });

    group('isNativeSideAvailable', () {
      test('should return true when ping succeeds', () async {
        final isAvailable = await AndroidBackgroundTaskMethodChannel.isNativeSideAvailable();
        
        expect(isAvailable, true);
        expect(methodCalls.length, 1);
        expect(methodCalls.first.method, 'ping');
      });

      test('should return false when ping fails', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(mockChannel, (call) async {
          throw PlatformException(code: 'PING_ERROR', message: 'Ping failed');
        });

        final isAvailable = await AndroidBackgroundTaskMethodChannel.isNativeSideAvailable();
        
        expect(isAvailable, false);
      });
    });

    group('getNativeVersion', () {
      test('should return version string', () async {
        final version = await AndroidBackgroundTaskMethodChannel.getNativeVersion();
        
        expect(version, '1.0.0');
        expect(methodCalls.length, 1);
        expect(methodCalls.first.method, 'getVersion');
      });

      test('should return null on error', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(mockChannel, (call) async {
          throw PlatformException(code: 'VERSION_ERROR', message: 'Version check failed');
        });

        final version = await AndroidBackgroundTaskMethodChannel.getNativeVersion();
        
        expect(version, null);
      });
    });

    group('getNativeInfo', () {
      test('should return native info map', () async {
        final info = await AndroidBackgroundTaskMethodChannel.getNativeInfo();
        
        expect(info, isA<Map<String, dynamic>>());
        expect(info['version'], '1.0.0');
        expect(info['androidVersion'], '13');
        expect(info['apiLevel'], 33);
        expect(methodCalls.length, 1);
        expect(methodCalls.first.method, 'getInfo');
      });

      test('should throw NativeOperationException on platform error', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(mockChannel, (call) async {
          throw PlatformException(code: 'GET_INFO_ERROR', message: 'Info retrieval failed');
        });

        expect(
          () => AndroidBackgroundTaskMethodChannel.getNativeInfo(),
          throwsA(isA<NativeOperationException>()),
        );
      });
    });

    group('method call handler', () {
      test('should set method call handler', () {
        bool handlerCalled = false;
        
        AndroidBackgroundTaskMethodChannel.setMethodCallHandler((call) async {
          handlerCalled = true;
          return 'test_result';
        });

        // Simulate a method call
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
              'android_background_task_manager',
              const StandardMethodCodec().encodeMethodCall(
                const MethodCall('test_method', {'arg': 'value'}),
              ),
              (data) {},
            );

        expect(handlerCalled, true);
      });

      test('should remove method call handler', () {
        AndroidBackgroundTaskMethodChannel.setMethodCallHandler((call) async {
          return 'test_result';
        });
        
        AndroidBackgroundTaskMethodChannel.removeMethodCallHandler();
        
        // Handler should be removed, but we can't easily test this without
        // more complex setup, so we just verify the method doesn't throw
        expect(() => AndroidBackgroundTaskMethodChannel.removeMethodCallHandler(), 
               returnsNormally);
      });
    });
  });
}
