package com.github.jing332.alistflutter

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import android.util.Log
import androidx.localbroadcastmanager.content.LocalBroadcastManager
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

class MainActivity : AudioServiceActivity() {
    companion object {
        private const val TAG = "MainActivity"
    }

    private val receiver by lazy { MyReceiver() }
    private var mEvent: com.github.jing332.pigeon.GeneratedApi.Event? = null

    @OptIn(DelicateCoroutinesApi::class)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        ShortCuts.buildShortCuts(this)
        LocalBroadcastManager.getInstance(this)
            .registerReceiver(receiver, IntentFilter(AListService.ACTION_STATUS_CHANGED))

        GeneratedPluginRegistrant.registerWith(this.flutterEngine!!)

        val binaryMessage = flutterEngine!!.dartExecutor.binaryMessenger
        com.github.jing332.pigeon.GeneratedApi.AppConfig.setUp(binaryMessage, AppConfigBridge)
        com.github.jing332.pigeon.GeneratedApi.Android.setUp(binaryMessage, AndroidBridge(this))
        com.github.jing332.pigeon.GeneratedApi.NativeCommon.setUp(binaryMessage, CommonBridge(this))
        mEvent = com.github.jing332.pigeon.GeneratedApi.Event(binaryMessage)

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


    inner class MyReceiver : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                AListService.ACTION_STATUS_CHANGED -> {
                    Log.d(TAG, "onReceive: ACTION_STATUS_CHANGED")

                    mEvent?.onServiceStatusChanged(AListService.isRunning, object : VoidResult {
                        override fun success() {}
                        override fun error(error: Throwable) {
                        }
                    })
                }



            }

        }
    }

}
