package com.github.jing332.alistflutter

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import android.util.Log
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import com.github.jing332.alistflutter.AListService.Companion.ACTION_STATUS_CHANGED
import com.github.jing332.alistflutter.AListService.Companion.EVENT_TYPE
import com.github.jing332.alistflutter.AListService.Companion.EVENT_TYPE_PROCESS_EXIT
import com.github.jing332.alistflutter.AListService.Companion.EVENT_TYPE_SHUTDOWN
import com.github.jing332.alistflutter.AListService.Companion.EVENT_TYPE_START_ERROR
import com.github.jing332.alistflutter.bridge.AndroidBridge
import com.github.jing332.alistflutter.bridge.AppConfigBridge
import com.github.jing332.alistflutter.bridge.CommonBridge
import com.github.jing332.alistflutter.model.ShortCuts
import com.github.jing332.alistflutter.model.alist.Logger
import com.github.jing332.pigeon.GeneratedApi
import com.github.jing332.pigeon.GeneratedApi.VoidResult
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugins.GeneratedPluginRegistrant
import kotlinx.coroutines.DelicateCoroutinesApi
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import kotlin.math.log

class MainActivity : AudioServiceActivity() {
    companion object {
        private const val TAG = "MainActivity"
    }

    private val receiver by lazy { MyReceiver() }
    private var mEvent: GeneratedApi.Event? = null

    @OptIn(DelicateCoroutinesApi::class)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        ShortCuts.buildShortCuts(this)
        LocalBroadcastManager.getInstance(this).registerReceiver(receiver, IntentFilter(ACTION_STATUS_CHANGED))

        GeneratedPluginRegistrant.registerWith(this.flutterEngine!!)

        val binaryMessage = flutterEngine!!.dartExecutor.binaryMessenger
        GeneratedApi.AppConfig.setUp(binaryMessage, AppConfigBridge)
        GeneratedApi.Android.setUp(binaryMessage, AndroidBridge(this))
        GeneratedApi.NativeCommon.setUp(binaryMessage, CommonBridge(this))
        mEvent = GeneratedApi.Event(binaryMessage)

        Logger.addListener(object : Logger.Listener {
            override fun onLog(level: Int, time: String, msg: String) {
                GlobalScope.launch(Dispatchers.Main) {
                    mEvent?.onServerLog(level.toLong(), time, msg, object : VoidResult {
                        override fun success() {
                        }

                        override fun error(error: Throwable) {
                        }
                    })
                }
            }

        })
    }

    override fun onDestroy() {
        super.onDestroy()

        LocalBroadcastManager.getInstance(this).unregisterReceiver(receiver)
    }


    // 接受服务器状态广播, 并回调 Flutter
    inner class MyReceiver : BroadcastReceiver() {
        private val callBack = object : VoidResult {
            override fun success() {
                android.util.Log.d(TAG, "success: 上报成功")
            }

            override fun error(error: Throwable) {
                android.util.Log.d(TAG, "error: 上报失败")
            }
        }

        override fun onReceive(context: Context, intent: Intent) {
            GlobalScope.launch(Dispatchers.Main) {
                when (intent.action) {
                    ACTION_STATUS_CHANGED -> {
                        val eventType = intent.getStringExtra(EVENT_TYPE)
                        val token = System.currentTimeMillis()
                        when (eventType) {
                            EVENT_TYPE_SHUTDOWN -> {
                                Log.d(TAG, "onReceive: ACTION_STATUS_CHANGED eventType: $eventType")
                                mEvent?.onShutdown("onShutdown" + token, callBack)
                            }

                            EVENT_TYPE_START_ERROR -> {
                                Log.d(TAG, "onReceive: ACTION_STATUS_CHANGED eventType: $eventType")
                                mEvent?.onStartError("onStartError" + token, "onProcessExit" + token, callBack)
                            }

                            EVENT_TYPE_PROCESS_EXIT -> {
                                Log.d(TAG, "onReceive: ACTION_STATUS_CHANGED eventType: $eventType")
                                mEvent?.onProcessExit(token, callBack)
                            }

                            else -> {
                                Log.d(TAG, "onReceive: ACTION_STATUS_CHANGED eventType: $eventType")
                                mEvent?.onServiceStatusChanged(AListService.isRunning, callBack)
                            }
                        }
                        // mEvent?.onServiceStatusChanged(AListService.isRunning, callBack)
                    }
                }
            }
        }
    }
}
