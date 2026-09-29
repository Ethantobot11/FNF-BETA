package;

#if (!wiiu || !cafe)

import haxe.CallStack;
import sys.io.File;
import sys.io.FileOutput;
import sys.FileSystem;
import citro.CitroG;
import citro.state.CitroState;

class CrashHandler {
    private static var logsDir:String = "sdmc:/FNF-PE/logs";
    private static var crashDir:String = "sdmc:/FNF-PE/crash";
    
    private static var logPath:String = "sdmc:/FNF-PE/logs/game_log.txt";
    private static var crashPath:String = "sdmc:/FNF-PE/crash/latest_crash.txt";
    
    private static var originalTrace:Dynamic;
    private static var logOutput:FileOutput = null;

    public static function init() {
        try {
            if (!FileSystem.exists("sdmc:/FNF-PE")) FileSystem.createDirectory("sdmc:/FNF-PE");
            if (!FileSystem.exists(logsDir)) FileSystem.createDirectory(logsDir);
            if (!FileSystem.exists(crashDir)) FileSystem.createDirectory(crashDir);

            logOutput = File.append(logPath, false);
            logOutput.writeString("\n--- Citro Engine 3DS Session Started: " + Date.now().toString() + " ---\n");
            logOutput.flush();
        } catch (e:Dynamic) {
            Sys.println("CRITICAL: Failed to initialize CrashHandler files: " + e);
        }

        originalTrace = haxe.Log.trace;
        
        haxe.Log.trace = function(v:Dynamic, ?infos:haxe.PosInfos) {
            if (originalTrace != null) {
                originalTrace(v, infos);
            }

            var fileName = (infos != null && infos.fileName != null) ? infos.fileName : "Unknown";
            var lineNumber = (infos != null) ? infos.lineNumber : 0;
            var className = (infos != null && infos.className != null) ? infos.className : "Unknown";
            
            var msg = '[${Date.now().toString()}] [$className:$fileName:$lineNumber]: $v\n';
            appendGeneralLog(msg);
        };
    }

    public static function appendGeneralLog(text:String) {
        try {
            if (logOutput != null) {
                logOutput.writeString(text);
                logOutput.flush();
            } else {
                var file = File.append(logPath, false);
                file.writeString(text);
                file.flush();
                file.close();
            }
        } catch (e:Dynamic) {
            Sys.println("Failed to write to general log: " + e);
        }
    }

    public static function logException(e:Dynamic, ?customMessage:String = "") {
        var stack = CallStack.toString(CallStack.exceptionStack());
        var fullLog = '\n========================================\n';
        fullLog += '[CRASH/ERROR] ${Date.now().toString()}\n';
        fullLog += 'Message: $customMessage\n';
        fullLog += 'Exception: $e\n';
        fullLog += 'CallStack:\n$stack\n';
        fullLog += '========================================\n';

        try {
            var file = File.write(crashPath, false);
            file.writeString(fullLog);
            file.flush();
            file.close();
        } catch (err:Dynamic) {
            Sys.println("Failed to write crash file: " + err);
        }

        appendGeneralLog(fullLog);
    }

    public static function protect(action:Void->Void, ?fallbackState:CitroState) {
        try {
            action();
        } catch (e:Dynamic) {
            logException(e, "Runtime Crash Caught in Protected Block!");
            
            try {
                var menuState:CitroState = (fallbackState != null) ? cast(fallbackState, CitroState) : new TitleState();
                CitroG.switchState(menuState);
            } catch (switchErr:Dynamic) {
                appendGeneralLog("Critical Error: Failed to switch back to menu state: " + switchErr);
            }
        }
    }
}

#end