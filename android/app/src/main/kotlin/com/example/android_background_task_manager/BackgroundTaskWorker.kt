package com.example.android_background_task_manager

import android.content.Context
import androidx.work.Worker
import androidx.work.WorkerParameters
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * Background Task Worker
 * 
 * This worker class handles the execution of background tasks. It receives
 * task information from WorkManager and executes the appropriate Flutter
 * callback function.
 */
class BackgroundTaskWorker(
    context: Context,
    params: WorkerParameters
) : Worker(context, params) {

    private var flutterEngine: FlutterEngine? = null
    private var methodChannel: MethodChannel? = null

    override fun doWork(): Result {
        return try {
            val taskId = inputData.getString("taskId")
            val data = inputData.getString("data")
            val retryOnFail = inputData.getBoolean("retryOnFail", true)
            val maxRetryAttempts = inputData.getInt("maxRetryAttempts", 5)

            if (taskId == null) {
                return Result.failure()
            }

            // Initialize Flutter engine if not already done
            if (flutterEngine == null) {
                initializeFlutterEngine()
            }

            // Execute the task
            executeTask(taskId, data, retryOnFail, maxRetryAttempts)

            Result.success()
        } catch (e: Exception) {
            // Log the error
            android.util.Log.e("BackgroundTaskWorker", "Task execution failed", e)
            
            // Return failure or retry based on configuration
            if (runAttemptCount < inputData.getInt("maxRetryAttempts", 5)) {
                Result.retry()
            } else {
                Result.failure()
            }
        }
    }

    /**
     * Initializes the Flutter engine for task execution.
     * 
     * This method creates a new Flutter engine instance and sets up the
     * method channel for communication with the Flutter side.
     */
    private fun initializeFlutterEngine() {
        try {
            flutterEngine = FlutterEngine(applicationContext)
            flutterEngine?.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
            )

            methodChannel = MethodChannel(
                flutterEngine?.dartExecutor?.binaryMessenger,
                "android_background_task_manager"
            )
        } catch (e: Exception) {
            android.util.Log.e("BackgroundTaskWorker", "Failed to initialize Flutter engine", e)
        }
    }

    /**
     * Executes a background task.
     * 
     * This method calls the Flutter side to execute the registered task
     * callback function.
     * 
     * @param taskId The unique identifier of the task to execute
     * @param data Additional data to pass to the task
     * @param retryOnFail Whether to retry on failure
     * @param maxRetryAttempts Maximum number of retry attempts
     */
    private fun executeTask(
        taskId: String,
        data: String?,
        retryOnFail: Boolean,
        maxRetryAttempts: Int
    ) {
        try {
            val arguments = mapOf(
                "taskId" to taskId,
                "data" to (data ?: "")
            )

            // Call the Flutter side to execute the task
            methodChannel?.invokeMethod("executeTask", arguments)
        } catch (e: Exception) {
            android.util.Log.e("BackgroundTaskWorker", "Failed to execute task $taskId", e)
            throw e
        }
    }

    /**
     * Cleans up resources when the worker is no longer needed.
     */
    override fun onStopped() {
        super.onStopped()
        try {
            flutterEngine?.destroy()
            flutterEngine = null
            methodChannel = null
        } catch (e: Exception) {
            android.util.Log.e("BackgroundTaskWorker", "Failed to cleanup resources", e)
        }
    }
}
