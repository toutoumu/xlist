//
//  AList.swift
//  Runner
//
//  Created by apple on 2024/8/15.
//

import Foundation
import Alistlib

/*这里是与go语言交互的逻辑代码*/
class AList: NSObject, AlistlibEventProtocol, AlistlibLogCallbackProtocol {

    static var instance = AList()

    private override init() {}

    /**
     * 获取配置文件路径
     */
    func dataDir() -> String {
        do {
            // 读取配置文件的路径
            let result = try AppConfigBridge.instance.getDataDir()
            return result
        } catch {
            // 如果没有则返回默认路径
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            return documentsDirectory.path
        }
    }

    /**
     * 初始化 Alist 服务
     */
    func initAlist(event:AlistlibEventProtocol) {
        // Alistlib.AlistlibSetConfigDebug(true) // debug 模式
        Alistlib.AlistlibSetConfigData(dataDir()) // 配置文件目录
        Alistlib.AlistlibSetConfigLogStd(true)
        
        // 初始化
        var error: NSError?
        Alistlib.AlistlibInit(event, self, &error)
        if (error == nil) {
            NSLog("AlistlibInit ok")
        } else {
            NSLog("AlistlibInit Error")
            let now = CFAbsoluteTimeGetCurrent()
            onLog(Int16(LogLevel.ERROR), time: Int64(now), message: "服务启动失败")
        }
    }
    
    /**
     * 启动 Alist
     */
    func startup() {
        // init()
        // self.initAlist()
        Alistlib.AlistlibStart(nil)
    }
    
    /**
     * 关闭 Alist
     */
    func shutdown() {
        var error: NSError?
        Alistlib.AlistlibShutdown(5000, &error)
        if (error == nil) {
            NSLog("ok")
        } else {
            NSLog("server start 服务关闭失败")
            let now = CFAbsoluteTimeGetCurrent()
            onLog(Int16(LogLevel.ERROR), time: Int64(now), message: "服务关闭失败")
        }
    }

    /**
     * AlistlibEventProtocol
     */
    func onProcessExit(_ code: Int) {

    }

    /**
     * AlistlibEventProtocol
     */
    func onStartError(_ t: String?, err: String?) {
        Logger.instance.log(level: LogLevel.FATAL, time: t ?? "", msg: err ?? "")
    }
    
    /**
     * AlistlibEventProtocol
     */
    func onShutdown(_ t: String?) {
        
    }

    /**
     * 设置 Alist 管理员密码
     */
    func setAdminPassword(pwd: String) {
        /*
        if (!isRunning()) {
            print("notRunning")
            self.initAlist(event:self)
        }else{
            print("isRunning")
        }
        Alistlib.AlistlibSetConfigData(dataDir())
        */
        Alistlib.AlistlibSetAdminPassword(pwd)
    }

    func getAdminPassword() throws -> String {
        return Alistlib.AlistlibGetAdminPassword()
    }
    
    func getAdminUsername() throws -> String {
        return Alistlib.AlistlibGetAdminUsername()
    }
    
    func getOutboundIPString() throws -> String {
        return Alistlib.AlistlibGetOutboundIPString()
    }
    
    /**
     * 是否正在运行
     */
    func isRunning() -> Bool {
        return Alistlib.AlistlibIsRunning("http")
    }

    /**
     * 获取 Alist 端口号
     */
    func getHttpPort() -> Int {
        return 5244
    }
    
    /**
     *  这个是 提供给 AList 服务端调用的
     *  打印日志, 这个日志会在日志列表展示,
     *  @param level LogLevel.xxx
     *  @param time let now = CFAbsoluteTimeGetCurrent()
     */
    func onLog(_ level: Int16, time: Int64, message: String?) {
        // MM-dd HH:mm:ss
        let date = Date(timeIntervalSince1970: Double(time))

        // 创建 DateFormatter 实例
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd HH:mm:ss"
        
        // 格式化日期
        let formattedDate = dateFormatter.string(from: date)
        
        Logger.instance.log(level: Int(level), time: formattedDate, msg: message ?? "")
    }
}
