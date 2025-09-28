package com.example.android_background_task_manager

import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.work.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.util.concurrent.TimeUnit

/**
 * Android Background Task Manager Plugin
 * 
 * This plugin provides native Android implementation for background task management
 * using WorkManager and AlarmManager. It handles task scheduling, execution, and
 * cancellation through a Flutter method channel.
 */
class AndroidBackgroundTaskManagerPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var workManager: WorkManager

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "android_background_task_manager")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        workManager = WorkManager.getInstance(context)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> initialize(result)
            "scheduleTask" -> scheduleTask(call, result)
            "cancelTask" -> cancelTask(call, result)
            "cancelAllTasks" -> cancelAllTasks(result)
            "getScheduledTasks" -> getScheduledTasks(result)
            "isTaskScheduled" -> isTaskScheduled(call, result)
            "executeTaskNow" -> executeTaskNow(call, result)
            "ping" -> result.success("pong")
            "getVersion" -> result.success("1.0.0")
            "getInfo" -> getInfo(result)
            else -> result.notImplemented()
        }
    }

    /**
     * Initializes the background task manager.
     * 
     * This method sets up the WorkManager and prepares the system for
     * background task management.
     */
    private fun initialize(result: Result) {
        try {
            // WorkManager is already initialized when we get the instance
            // Just verify it's working
            result.success("Initialized successfully")
        } catch (e: Exception) {
            result.error("INIT_ERROR", "Failed to initialize: ${e.message}", null)
        }
    }

    /**
     * Schedules a background task.
     * 
     * This method creates a WorkRequest based on the provided options
     * and schedules it using WorkManager.
     */
    private fun scheduleTask(call: MethodCall, result: Result) {
        try {
            val arguments = call.arguments as Map<String, Any>
            val taskId = arguments["id"] as String
            val periodic = arguments["periodic"] as Boolean
            val frequency = arguments["frequency"] as? Long
            val initialDelay = arguments["initialDelay"] as Long
            val requiresCharging = arguments["requiresCharging"] as Boolean
            val requiresWifi = arguments["requiresWifi"] as Boolean
            val retryOnFail = arguments["retryOnFail"] as Boolean
            val maxRetryAttempts = arguments["maxRetryAttempts"] as Int
            val data = arguments["data"] as? Map<String, Any>

            // Build constraints
            val constraints = Constraints.Builder()
                .apply {
                    if (requiresCharging) {
                        setRequiredNetworkType(NetworkType.NOT_REQUIRED)
                        setRequiresCharging(true)
                    }
                    if (requiresWifi) {
                        setRequiredNetworkType(NetworkType.UNMETERED)
                    }
                }
                .build()

            // Build input data
            val inputData = Data.Builder()
                .putString("taskId", taskId)
                .putString("data", data?.toString() ?: "")
                .putBoolean("retryOnFail", retryOnFail)
                .putInt("maxRetryAttempts", maxRetryAttempts)
                .build()

            // Create work request
            val workRequest = if (periodic) {
                // Periodic work request
                val frequencyMs = frequency ?: 15 * 60 * 1000L // Default 15 minutes
                val frequencyMinutes = TimeUnit.MILLISECONDS.toMinutes(frequencyMs)
                
                PeriodicWorkRequest.Builder(
                    BackgroundTaskWorker::class.java,
                    frequencyMinutes,
                    TimeUnit.MINUTES
                )
                    .setInitialDelay(initialDelay, TimeUnit.MILLISECONDS)
                    .setConstraints(constraints)
                    .setInputData(inputData)
                    .setBackoffCriteria(
                        if (retryOnFail) BackoffPolicy.EXPONENTIAL else BackoffPolicy.LINEAR,
                        WorkRequest.MIN_BACKOFF_MILLIS,
                        TimeUnit.MILLISECONDS
                    )
                    .build()
            } else {
                // One-time work request
                OneTimeWorkRequest.Builder(BackgroundTaskWorker::class.java)
                    .setInitialDelay(initialDelay, TimeUnit.MILLISECONDS)
                    .setConstraints(constraints)
                    .setInputData(inputData)
                    .setBackoffCriteria(
                        if (retryOnFail) BackoffPolicy.EXPONENTIAL else BackoffPolicy.LINEAR,
                        WorkRequest.MIN_BACKOFF_MILLIS,
                        TimeUnit.MILLISECONDS
                    )
                    .build()
            }

            // Enqueue the work request
            workManager.enqueueUniqueWork(
                taskId,
                if (periodic) ExistingPeriodicWorkPolicy.REPLACE else ExistingWorkPolicy.REPLACE,
                workRequest
            )

            result.success("Task scheduled successfully")
        } catch (e: Exception) {
            result.error("SCHEDULE_ERROR", "Failed to schedule task: ${e.message}", null)
        }
    }

    /**
     * Cancels a specific task.
     */
    private fun cancelTask(call: MethodCall, result: Result) {
        try {
            val arguments = call.arguments as Map<String, Any>
            val taskId = arguments["taskId"] as String

            workManager.cancelUniqueWork(taskId)
            result.success("Task cancelled successfully")
        } catch (e: Exception) {
            result.error("CANCEL_ERROR", "Failed to cancel task: ${e.message}", null)
        }
    }

    /**
     * Cancels all tasks.
     */
    private fun cancelAllTasks(result: Result) {
        try {
            workManager.cancelAllWork()
            result.success("All tasks cancelled successfully")
        } catch (e: Exception) {
            result.error("CANCEL_ALL_ERROR", "Failed to cancel all tasks: ${e.message}", null)
        }
    }

    /**
     * Gets information about all scheduled tasks.
     */
    private fun getScheduledTasks(result: Result) {
        try {
            // This is a simplified implementation
            // In a real implementation, you would track task states
            result.success(emptyList<Map<String, Any>>())
        } catch (e: Exception) {
            result.error("GET_TASKS_ERROR", "Failed to get scheduled tasks: ${e.message}", null)
        }
    }

    /**
     * Checks if a specific task is scheduled.
     */
    private fun isTaskScheduled(call: MethodCall, result: Result) {
        try {
            val arguments = call.arguments as Map<String, Any>
            val taskId = arguments["taskId"] as String

            // This is a simplified implementation
            // In a real implementation, you would check WorkManager state
            result.success(false)
        } catch (e: Exception) {
            result.error("IS_SCHEDULED_ERROR", "Failed to check task status: ${e.message}", null)
        }
    }

    /**
     * Executes a task immediately.
     */
    private fun executeTaskNow(call: MethodCall, result: Result) {
        try {
            val arguments = call.arguments as Map<String, Any>
            val taskId = arguments["taskId"] as String

            // Create a one-time work request for immediate execution
            val workRequest = OneTimeWorkRequest.Builder(BackgroundTaskWorker::class.java)
                .setInputData(Data.Builder().putString("taskId", taskId).build())
                .build()

            workManager.enqueue(workRequest)
            result.success("Task execution initiated")
        } catch (e: Exception) {
            result.error("EXECUTE_ERROR", "Failed to execute task: ${e.message}", null)
        }
    }

    /**
     * Gets information about the native implementation.
     */
    private fun getInfo(result: Result) {
        try {
            val info = mapOf(
                "version" to "1.0.0",
                "androidVersion" to Build.VERSION.RELEASE,
                "apiLevel" to Build.VERSION.SDK_INT,
                "workManagerVersion" to "2.8.1",
                "supportsWorkManager" to true,
                "supportsAlarmManager" to true
            )
            result.success(info)
        } catch (e: Exception) {
            result.error("GET_INFO_ERROR", "Failed to get info: ${e.message}", null)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "android_background_task_manager")
            val plugin = AndroidBackgroundTaskManagerPlugin()
            plugin.channel = channel
            plugin.context = registrar.context()
            plugin.workManager = WorkManager.getInstance(registrar.context())
            channel.setMethodCallHandler(plugin)
        }
    }
}
