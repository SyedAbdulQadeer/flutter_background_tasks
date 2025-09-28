package com.example.android_background_task_manager

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.work.WorkManager

/**
 * Boot Receiver
 * 
 * This receiver handles device boot events and restarts scheduled
 * background tasks after the device has been rebooted.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_PACKAGE_REPLACED -> {
                // Restart scheduled tasks after boot
                restartScheduledTasks(context)
            }
        }
    }

    /**
     * Restarts all scheduled tasks after device boot.
     * 
     * This method is called when the device boots up to ensure that
     * scheduled background tasks continue to work after a reboot.
     * 
     * @param context The application context
     */
    private fun restartScheduledTasks(context: Context) {
        try {
            // In a real implementation, you would restore tasks from persistence
            // For now, we just log that the receiver was triggered
            android.util.Log.d("BootReceiver", "Device booted, restarting scheduled tasks")
            
            // You could implement task restoration logic here
            // This would involve reading from SharedPreferences or a database
            // and rescheduling tasks with WorkManager
        } catch (e: Exception) {
            android.util.Log.e("BootReceiver", "Failed to restart scheduled tasks", e)
        }
    }
}
