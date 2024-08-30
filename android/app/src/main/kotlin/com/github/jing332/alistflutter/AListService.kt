package com.github.jing332.alistflutter

import alistlib.Alistlib
import alistlib.Event
import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.icu.lang.UCharacter.GraphemeClusterBreak.T
import android.nfc.Tag
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.ServiceCompat.startForeground
import androidx.core.content.ContextCompat.getSystemService
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import com.github.jing332.alistflutter.AListService.Companion.ACTION_COPY_ADDRESS
import com.github.jing332.alistflutter.AListService.Companion.FOREGROUND_ID
import com.github.jing332.alistflutter.AListService.Companion.NOTIFICATION_CHAN_ID
import com.github.jing332.alistflutter.config.AppConfig
import com.github.jing332.alistflutter.constant.LogLevel
import com.github.jing332.alistflutter.constant.LogLevel.Companion
import com.github.jing332.alistflutter.model.alist.AList
import com.github.jing332.alistflutter.model.alist.Logger
import com.github.jing332.alistflutter.utils.AndroidUtils.registerReceiverCompat
import com.github.jing332.alistflutter.utils.ClipboardUtils
import com.github.jing332.alistflutter.utils.ToastUtils.toast
import com.github.jing332.pigeon.GeneratedApi
import com.github.jing332.utils.NativeLib
import io.xlist.R
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import splitties.systemservices.powerManager
import java.io.BufferedReader
import java.io.IOException
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.TimeUnit
import kotlin.math.log

class AListService : Service() {
    companion object {
        const val TAG = "AlistService"

        // 关闭
        const val ACTION_SHUTDOWN =
            "com.github.jing332.alistandroid.service.AlistService.ACTION_SHUTDOWN"

        // 复制访问地址
        const val ACTION_COPY_ADDRESS =
            "com.github.jing332.alistandroid.service.AlistService.ACTION_COPY_ADDRESS"

        // 状态改变
        const val ACTION_STATUS_CHANGED =
            "com.github.jing332.alistandroid.service.AlistService.ACTION_STATUS_CHANGED"

        // 广播参数
        const val EVENT_TYPE = "event_type"
        const val EVENT_TYPE_STARTUP = "startup"
        const val EVENT_TYPE_SHUTDOWN = "shutdown"
        const val EVENT_TYPE_START_ERROR = "start_error"
        const val EVENT_TYPE_PROCESS_EXIT = "process_exit"

        // 通知相关
        const val NOTIFICATION_CHAN_ID = "alist_server"
        const val FOREGROUND_ID = 5224

        // 运行状态
        var isRunning: Boolean = false
    }

    private val mScope = CoroutineScope(Job())
    private val viewModelScope = CoroutineScope(Dispatchers.Main)
    private val mNotificationReceiver = NotificationActionReceiver()
    private var mWakeLock: PowerManager.WakeLock? = null
    private var mLocalAddress: String = ""

    override fun onBind(p0: Intent?): IBinder? = null

    @Suppress("DEPRECATION")
    private fun notifyStatusChanged(event: String) {
        LocalBroadcastManager.getInstance(this)
            .sendBroadcast(Intent(ACTION_STATUS_CHANGED).apply {
                putExtra(EVENT_TYPE, event)
            })

        if (!isRunning) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                stopForeground(true)
            }

            stopSelf()
        }
    }

    @SuppressLint("WakelockTimeout")
    override fun onCreate() {
        super.onCreate()

        initOrUpdateNotification()

        if (AppConfig.isWakeLockEnabled) {
            mWakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "alist::service")
            mWakeLock?.acquire()
        }

        // 通知栏通知, 按钮点击事件
        registerReceiverCompat(mNotificationReceiver, ACTION_SHUTDOWN, ACTION_COPY_ADDRESS)
    }


    @Suppress("DEPRECATION")
    override fun onDestroy() {
        super.onDestroy()

        mWakeLock?.release()
        mWakeLock = null

        // 移除监听
        stopForeground(true)
        unregisterReceiver(mNotificationReceiver)
    }


    private fun startOrShutdown() {
        viewModelScope.launch {
            if (isRunning) {
                AList.shutdown()
            } else {
                toast(getString(R.string.starting))
                AList.init(object : Event {
                    override fun onShutdown(p0: String) {
                        Log.d(TAG, "onShutdown: $p0")
                        // if (!AList.isRunning()) {
                        isRunning = false
                        notifyStatusChanged(EVENT_TYPE_SHUTDOWN)
                        // }
                    }

                    override fun onStartError(type: String, msg: String) {
                        isRunning = false
                        Log.e(TAG, "onStartError: $type, $msg")
                        Logger.log(LogLevel.FATAL, type, msg)
                        notifyStatusChanged(EVENT_TYPE_START_ERROR)
                    }

                    override fun onProcessExit(code: Long) {
                        isRunning = false
                        Log.e(TAG, "onProcessExit")
                        // Logger.log(LogLevel.FATAL, type, "onProcessExit")
                        notifyStatusChanged(EVENT_TYPE_PROCESS_EXIT)
                    }
                })
                AList.startup()
                try {
                    delay(1000)
                    val host = NativeLib.getLocalIp()// AList.getOutboundIPString()
                    val port = AList.getHttpPort()
                    val data = fetchUrlWithRetry("http://${host}:${port}/ping")
                    Log.e(TAG, data ?: "--------")
                    isRunning = true
                    notifyStatusChanged(EVENT_TYPE_STARTUP)
                } catch (e: Exception) {
                    Log.e(TAG, "onStartError", e)
                    isRunning = false
                    notifyStatusChanged(EVENT_TYPE_START_ERROR)
                }
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startOrShutdown()
        return super.onStartCommand(intent, flags, startId)
    }

    private fun localAddress(): String = Alistlib.getOutboundIPString()


    @Suppress("DEPRECATION")
    private fun initOrUpdateNotification() {
        // Android 12(S)+ 必须指定PendingIntent.FLAG_
        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
            PendingIntent.FLAG_IMMUTABLE
        else
            0

        /*点击通知跳转*/
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            pendingIntentFlags
        )
        /*当点击退出按钮时发送广播*/
        val shutdownAction: PendingIntent =
            PendingIntent.getBroadcast(
                this,
                0,
                Intent(ACTION_SHUTDOWN),
                pendingIntentFlags
            )
        val copyAddressPendingIntent =
            PendingIntent.getBroadcast(
                this,
                0,
                Intent(ACTION_COPY_ADDRESS),
                pendingIntentFlags
            )

        // val color = com.github.jing332.alistandroid.ui.theme.seed.androidColor
        val smallIconRes: Int
        val builder = Notification.Builder(applicationContext)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {/*Android 8.0+ 要求必须设置通知信道*/
            val chan = NotificationChannel(
                NOTIFICATION_CHAN_ID,
                getString(R.string.alist_server),
                NotificationManager.IMPORTANCE_NONE
            )
            // chan.lightColor = color
            chan.lockscreenVisibility = Notification.VISIBILITY_PRIVATE
            val service = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            service.createNotificationChannel(chan)
            smallIconRes = when ((0..1).random()) {
                0 -> R.drawable.server
                1 -> R.drawable.server2
                else -> R.drawable.server2
            }

            builder.setChannelId(NOTIFICATION_CHAN_ID)
        } else {
            smallIconRes = R.mipmap.ic_launcher
        }
        val notification = builder
            // .setColor(color)
            .setContentTitle(getString(R.string.alist_server_running))
            .setContentText(localAddress())
            .setSmallIcon(smallIconRes)
            .setContentIntent(pendingIntent)
            .addAction(0, getString(R.string.shutdown), shutdownAction)
            .addAction(0, getString(R.string.copy_address), copyAddressPendingIntent)

            .build()

        startForeground(FOREGROUND_ID, notification)
    }

    inner class NotificationActionReceiver : BroadcastReceiver() {
        override fun onReceive(ctx: Context?, intent: Intent?) {
            when (intent?.action) {
                ACTION_SHUTDOWN -> {
                    startOrShutdown()
                }

                ACTION_COPY_ADDRESS -> {
                    ClipboardUtils.copyText("AList", localAddress())
                    toast(R.string.address_copied)
                }
            }
        }
    }

    private val client = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(15, TimeUnit.SECONDS)
        .writeTimeout(15, TimeUnit.SECONDS)
        .build()

    private suspend fun fetchUrl(url: String): String? = withContext(Dispatchers.IO) {
        val request = Request.Builder()
            .url(url)
            .build()

        try {
            val response = client.newCall(request).execute()
            if (!response.isSuccessful) {
                println("Unexpected code $response")
                throw IOException("Unexpected code $response")
            }
            response.body?.string()
        } catch (e: Exception) {
            println("Error: ${e.message}")
            e.printStackTrace()
            null
        }
    }

    private suspend fun fetchUrlWithRetry(url: String, maxRetries: Int = 3): String? = withContext(Dispatchers.IO) {
        var retries = 0
        while (retries < maxRetries) {
            try {
                return@withContext fetchUrl(url)
            } catch (e: Exception) {
                println("Error: ${e.message}")
                retries++
            }
        }
        null
    }
}




