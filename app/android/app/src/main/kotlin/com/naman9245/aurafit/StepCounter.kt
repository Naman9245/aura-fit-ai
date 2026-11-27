package com.naman9245.aurafit

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Handler
import android.os.HandlerThread
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import org.json.JSONArray
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * The phone's own step sensor. It counts steps since the phone last started,
 * so readings are kept with their times, every 15 minutes in the background
 * and whenever the app asks, and a day's steps are what the count grew by
 * within the day. Only this phone keeps the readings; the app saves the
 * day's total like any other steps.
 */
object StepCounter {
    private const val PREFS = "aurafit_steps"
    private const val READINGS = "readings"
    private const val WORK = "aurafit-step-readings"
    private const val KEEP_MS = 3L * 24 * 60 * 60 * 1000

    fun available(context: Context): Boolean =
        sensorManager(context).getDefaultSensor(Sensor.TYPE_STEP_COUNTER) != null

    /** Reads the sensor every 15 minutes, even with the app closed. */
    fun schedule(context: Context) {
        val request = PeriodicWorkRequestBuilder<StepWorker>(15, TimeUnit.MINUTES).build()
        WorkManager.getInstance(context)
            .enqueueUniquePeriodicWork(WORK, ExistingPeriodicWorkPolicy.KEEP, request)
    }

    /**
     * Reads the sensor once and keeps the reading. Blocks for up to
     * [timeoutMs], so never call it on the main thread.
     */
    fun readNow(context: Context, timeoutMs: Long = 5000) {
        val manager = sensorManager(context)
        val sensor = manager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER) ?: return
        val thread = HandlerThread("aurafit-steps").apply { start() }
        val latch = CountDownLatch(1)
        var count: Float? = null
        val listener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                count = event.values[0]
                latch.countDown()
            }

            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
        }
        try {
            manager.registerListener(
                listener,
                sensor,
                SensorManager.SENSOR_DELAY_NORMAL,
                Handler(thread.looper),
            )
            latch.await(timeoutMs, TimeUnit.MILLISECONDS)
        } finally {
            manager.unregisterListener(listener)
            thread.quitSafely()
        }
        count?.let { record(context, System.currentTimeMillis(), it.toDouble()) }
    }

    /**
     * Steps between two times: how much the count grew, sharing the growth
     * between two readings by time when only part of it falls inside. A
     * count lower than the one before means the phone restarted, and counts
     * from zero.
     */
    fun stepsBetween(context: Context, start: Long, end: Long): Long {
        val readings = load(context)
        var steps = 0.0
        for (i in 1 until readings.size) {
            val (t0, c0) = readings[i - 1]
            val (t1, c1) = readings[i]
            if (t1 <= start || t0 >= end || t1 <= t0) continue
            val grew = if (c1 >= c0) c1 - c0 else c1
            val overlap = minOf(t1, end) - maxOf(t0, start)
            steps += grew * overlap.toDouble() / (t1 - t0)
        }
        return Math.round(steps)
    }

    @Synchronized
    private fun record(context: Context, time: Long, count: Double) {
        val readings = load(context).toMutableList()
        readings.add(time to count)
        readings.sortBy { it.first }
        // Three days back is plenty; keep the last one before that, to
        // count from.
        val cutoff = time - KEEP_MS
        val firstKept = readings.indexOfFirst { it.first >= cutoff }.coerceAtLeast(1) - 1
        val kept = readings.drop(firstKept.coerceAtLeast(0))
        val json = JSONArray()
        for ((t, c) in kept) json.put(JSONArray().put(t).put(c))
        prefs(context).edit().putString(READINGS, json.toString()).apply()
    }

    private fun load(context: Context): List<Pair<Long, Double>> {
        val raw = prefs(context).getString(READINGS, null) ?: return emptyList()
        val json = JSONArray(raw)
        return (0 until json.length()).map {
            val pair = json.getJSONArray(it)
            pair.getLong(0) to pair.getDouble(1)
        }
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun sensorManager(context: Context) =
        context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
}

/** Takes a step reading in the background. */
class StepWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    override fun doWork(): Result {
        StepCounter.readNow(applicationContext)
        return Result.success()
    }
}
