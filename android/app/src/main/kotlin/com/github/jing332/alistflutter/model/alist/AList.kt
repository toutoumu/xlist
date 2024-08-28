package com.github.jing332.alistflutter.model.alist

import alistlib.Alistlib
import alistlib.Event
import alistlib.LogCallback
import android.annotation.SuppressLint
import android.util.Log
import com.github.jing332.alistflutter.app
import com.github.jing332.alistflutter.config.AppConfig
import com.github.jing332.alistflutter.constant.LogLevel
import com.github.jing332.alistflutter.utils.ToastUtils.longToast
import io.xlist.R
import java.io.File
import java.text.SimpleDateFormat
import java.util.Locale
import kotlin.math.log

object AList {
    const val TAG = "AList"

    val context = app

    val dataDir: String
        get() = AppConfig.dataDir

    val configPath: String
        get() = "$dataDir${File.separator}config.json"


    fun init(event: Event) {
        runCatching {
            Log.e(TAG, "init")
            Alistlib.setConfigData(dataDir)
            Alistlib.setConfigLogStd(true)
            Alistlib.init(event, object : LogCallback {
                override fun onLog(level: Short, time: Long, log: String) {
                    Log.d(TAG, "onLog: $level, $time, $log")
                    Logger.log(level.toInt(), mDateFormatter.format(time), log)
                }
            })
        }.onFailure {
            Log.e(TAG, "init:", it)
        }
    }

    private val mDateFormatter by lazy { SimpleDateFormat("MM-dd HH:mm:ss", Locale.getDefault()) }


    fun isRunning(): Boolean {
        val isRunning = Alistlib.isRunning("http")
        Log.d(TAG, "isRunning:  $isRunning")
        return isRunning
    }

    fun setAdminPassword(pwd: String) {
        // if (!isRunning()) init()
        Log.d(TAG, "setAdminPassword: $pwd")
        // Alistlib.setConfigData(dataDir)
        Alistlib.setAdminPassword(pwd)
    }

    fun getAdminPassword(): String {
        val pwd = Alistlib.getAdminPassword()
        Log.d(TAG, "getAdminPassword: $pwd")
        return pwd
    }

    fun getAdminUsername(): String {
        val userName = Alistlib.getAdminUsername()
        Log.d(TAG, "getAdminUsername: $userName")
        return userName
    }

    fun getOutboundIPString(): String {
        val ip = Alistlib.getOutboundIPString()
        Log.d(TAG, "getOutboundIPString: $ip")
        return ip
    }

    fun shutdown() {
        Log.d(TAG, "shutdown")
        runCatching {
            Alistlib.shutdown(5000)
        }.onFailure {
            context.longToast(R.string.shutdown_failed)
        }
    }

    @SuppressLint("SdCardPath")
    fun startup() {
        Log.d(TAG, "startup: $dataDir")
        // init()
        Alistlib.start()
    }

    fun getHttpPort(): Int {
        return AListConfigManager.config().scheme.httpPort
    }
}