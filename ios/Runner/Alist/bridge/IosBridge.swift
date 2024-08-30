//
//  IosBridge.swift
//  Runner
//
//  Created by apple on 2024/8/15.
//

import Foundation
import Alistlib
import Combine

/**
 * 提供给 Flutter 调用的接口
 */
class IosBridge: NSObject, Android ,AlistlibEventProtocol{
    
    var event: Event

    init(event: Event) {
        self.event = event
    }
    
    var isRuning = false

    /**
     * 添加快捷启动图标到桌面
     */
    func addShortcut() throws {

    }

    /**
     * 启动 | 关闭 AList
     */
    func startService() throws {
        if (!isRuning) {
            // 启动通知栏
            CommonBridge.showToast(message: "启动中...")
            AList.instance.initAlist(event: self)
            AList.instance.startup()
            HCKeepBGRunManager.shared.startBGRun()
            
            // 通知 Flutter 运行状态改变了
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                // todo 调用 ping, 检测是否已经启动
                self.isRuning = true
                NotificationManager.shared.scheduleNotification("AListServer", body: "服务正在运行中")
                self.event.onServiceStatusChanged(isRunning: self.isRuning){ result in
                    switch result {
                    case .success:
                        print("状态日志已成功上报")
                    case .failure(let error):
                        print("状态上报失败: \(error)")
                    }
                }
            }
        } else {
            // 停止状态
            isRuning = false
            AList.instance.shutdown()
            HCKeepBGRunManager.shared.stopBGRun()
            NotificationManager.shared.removeNotification()
        }
        
        /*
        // 延迟3秒上报启动状态
        //DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
            if(AList.instance.isRunning()){
                print("Alist 运行中....")
            }else{
                print("Alist 未运行....")
            }
            self.event.onServiceStatusChanged(isRunning: self.isRuning){ result in
                switch result {
                case .success:
                    print("状态日志已成功上报")
                case .failure(let error):
                    print("状态上报失败: \(error)")
                }
            }
        }
        */
    }

    func setAdminPwd(pwd: String) throws {
        AList.instance.setAdminPassword(pwd: pwd)
    }
    
    func getAdminPassword() throws -> String {
        do {
            let result =  try AList.instance.getAdminPassword()
            return result
        } catch {
            return ""
        }
    }
    
    func getAdminUsername() throws -> String {
        do {
            let result =  try AList.instance.getAdminUsername()
            return result
        } catch {
            return ""
        }
    }
    
    func getOutboundIPString() throws -> String {
        do {
            let result =  try AList.instance.getOutboundIPString()
            return result
        } catch {
            return ""
        }
    }

    func getAListHttpPort() throws -> Int64 {
        return Int64(AList.instance.getHttpPort())
    }

    func isRunning() throws -> Bool {
        // return AList.instance.isRunning()
        return isRuning
    }

    func getAListVersion() throws -> String {
        return "v3.36.0"
    }
    
    /**
     * AList 进程退出
     */
    func onProcessExit(_ code: Int) {
        var time = Date().timeIntervalSince1970
        event.onProcessExit(var1: Int64(time)) {result in
            switch result{
            case .success:
                print("");
            case .failure(let error):
                // result(error)
                print("");
            }
        }
    }

    /**
     *  AList 启动错误
     */
    func onStartError(_ t: String?, err: String?) {
        Logger.instance.log(level: LogLevel.FATAL, time: t ?? "", msg: err ?? "")
        event.onStartError(var1: t ?? "", var2: err ?? ""){result in
            switch result{
            case .success:
                print("");
            case .failure(let error):
                // result(error)
                print("");
            }
        }
    }
    
    /**
     * 正在停止 AList
     */
    func onShutdown(_ t: String?) {
        event.onShutdown(var1: t ?? "") { result in
            switch result {
            case .success:
                // result(nil)
                print("");
            case .failure(let error):
                // result(error)
                print("");
            }
        }
    }
}
