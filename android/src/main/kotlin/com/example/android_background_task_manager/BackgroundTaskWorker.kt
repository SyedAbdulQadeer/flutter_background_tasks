package com.example.android_background_task_manager

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters

/**
 * Background Task Worker
 * 
 * This worker class handles the execution of background tasks without
 * requiring Flutter engine initialization in background threads.
 * 
 * Instead of trying to run Flutter/Dart code in background, this worker:
 * 1. Performs native Android background operations
 * 2. Stores results in SharedPreferences or database
 * 3. Notifies the Flutter app when it becomes active
 */
class BackgroundTaskWorker(
    context: Context,
    params: WorkerParameters
) : Worker(context, params) {

    companion object {
        private const val TAG = "BackgroundTaskWorker"
        private const val PREFS_NAME = "background_task_results"
        private const val KEY_TASK_RESULTS = "task_results"
    }

    override fun doWork(): Result {
        return try {
            Log.d(TAG, "Starting background task execution")
            
            val taskId = inputData.getString("taskId")
            val data = inputData.getString("data")
            val taskType = inputData.getString("taskType") ?: "default"
            
            if (taskId == null) {
                Log.e(TAG, "Task ID is null")
                return Result.failure()
            }

            Log.d(TAG, "Executing task: $taskId with type: $taskType")
            
            // Execute the background task based on its type
            val result = when (taskType) {
                "periodic" -> executePeriodicTask(taskId, data)
                "oneTime" -> executeOneTimeTask(taskId, data)
                "delayed" -> executeDelayedTask(taskId, data)
                else -> executeDefaultTask(taskId, data)
            }
            
            // Store the result for the Flutter app to retrieve later
            storeTaskResult(taskId, result)
            
            Log.d(TAG, "Task $taskId completed successfully with result: $result")
            Result.success()
            
        } catch (e: Exception) {
            Log.e(TAG, "Task execution failed", e)
            
            // Store error result
            inputData.getString("taskId")?.let { taskId ->
                storeTaskResult(taskId, "Error: ${e.message}")
            }
            
            // Determine if we should retry
            val maxRetryAttempts = inputData.getInt("maxRetryAttempts", 3)
            if (runAttemptCount < maxRetryAttempts) {
                Log.d(TAG, "Retrying task, attempt ${runAttemptCount + 1}/$maxRetryAttempts")
                Result.retry()
            } else {
                Log.e(TAG, "Task failed after $maxRetryAttempts attempts")
                Result.failure()
            }
        }
    }

    /**
     * Executes a periodic background task
     */
    private fun executePeriodicTask(taskId: String, data: String?): String {
        Log.d(TAG, "Executing periodic task: $taskId")
        
        // Simulate periodic work (e.g., syncing data, checking for updates)
        Thread.sleep(1000)
        
        val timestamp = System.currentTimeMillis()
        return "Periodic task completed at $timestamp. Data: $data"
    }

    /**
     * Executes a one-time background task
     */
    private fun executeOneTimeTask(taskId: String, data: String?): String {
        Log.d(TAG, "Executing one-time task: $taskId")
        
        // Simulate one-time work (e.g., uploading file, processing data)
        Thread.sleep(2000)
        
        return "One-time task completed successfully. Processed: $data"
    }

    /**
     * Executes a delayed background task
     */
    private fun executeDelayedTask(taskId: String, data: String?): String {
        Log.d(TAG, "Executing delayed task: $taskId")
        
        // Simulate delayed work (e.g., scheduled notification, cleanup)
        Thread.sleep(500)
        
        return "Delayed task executed. Data processed: $data"
    }

    /**
     * Executes a default background task
     */
    private fun executeDefaultTask(taskId: String, data: String?): String {
        Log.d(TAG, "Executing default task: $taskId")
        
        // Default task implementation
        return "Default task completed with data: $data"
    }

    /**
     * Stores the task result in SharedPreferences so the Flutter app can retrieve it
     */
    private fun storeTaskResult(taskId: String, result: String) {
        try {
            val sharedPrefs: SharedPreferences = applicationContext.getSharedPreferences(
                PREFS_NAME, 
                Context.MODE_PRIVATE
            )
            
            val editor = sharedPrefs.edit()
            val timestamp = System.currentTimeMillis()
            val taskResult = mapOf(
                "taskId" to taskId,
                "result" to result,
                "timestamp" to timestamp,
                "status" to "completed"
            ).toString()
            
            // Store individual task result
            editor.putString("task_$taskId", taskResult)
            
            // Also maintain a list of completed tasks
            val completedTasks = sharedPrefs.getStringSet("completed_tasks", mutableSetOf()) ?: mutableSetOf()
            completedTasks.add(taskId)
            editor.putStringSet("completed_tasks", completedTasks)
            
            editor.apply()
            
            Log.d(TAG, "Task result stored for task: $taskId")
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to store task result", e)
        }
    }

    override fun onStopped() {
        super.onStopped()
        Log.d(TAG, "Background task worker stopped")
    }
}
