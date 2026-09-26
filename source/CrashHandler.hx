package;

#if (!wiiu || !cafe)

import haxe.CallStack;
import sys.io.File;
import sys.io.FileOutput;
import sys.FileSystem;
import citro.CitroG;
import citro.state.CitroState;

class CrashHandler {
    private static var logsDir:String = "sdmc:/Deltarune/logs";
    private static var crashDir:String = "sdmc:/Deltarune/crash";
    
    private static var logPath:String = "sdmc:/Deltarune/logs/game_log.txt";
    private static var crashPath:String = "sdmc:/Deltarune/crash/latest_crash.txt";
    
    private static var originalTrace:Dynamic;
    private static var logOutput:FileOutput = null;

    public static function init() {
        try {
            if (!FileSystem.isDirectory(logsDir)) {
                FileSystem.createDirectory(logsDir);
            }
            if (!FileSystem.isDirectory(crashDir)) {
                FileSystem.createDirectory(crashDir);
            }

            logOutput = File.append(logPath, false);
            logOutput.writeString("--- Citro Engine 3DS Session Started ---\n");
            logOutput.flush();
        } catch (e:Dynamic) {
            trace("CRITICAL: Failed to initialize CrashHandler files: " + e);
        }

        originalTrace = haxe.Log.trace;
        haxe.Log.trace = function(v:Dynamic, ?infos:haxe.PosInfos) {
            originalTrace(v, infos);

            var fileName = (infos != null && infos.fileName != null) ? infos.fileName : "Unknown";
            var lineNumber = (infos != null) ? infos.lineNumber : 0;
            var msg = '[$fileName:$lineNumber]: $v\n';
            
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
            originalTrace("Failed to write to general log: " + e);
        }
    }

    public static function logException(e:Dynamic, ?customMessage:String = "") {
        var stack = CallStack.toString(CallStack.exceptionStack());
        var fullLog = '\n[CRASH/ERROR] $customMessage\nException: $e\nCallStack:\n$stack\n-------------------\n';

        try {
            var file = File.write(crashPath, false);
            file.writeString(fullLog);
            file.flush();
            file.close();
        } catch (err:Dynamic) {
            originalTrace("Failed to write crash file: " + err);
        }

        appendGeneralLog(fullLog);
    }

    public static function protect(action:Void->Void, ?fallbackState:CitroState) {
        try {
            action();
        } catch (e:Dynamic) {
            logException(e, "Runtime Crash Caught!");
            
            try {
                var menuState = fallbackState != null ? fallbackState : new ThreeDSMainMenuState();
                CitroG.switchState(menuState);
            } catch (switchErr:Dynamic) {
                appendGeneralLog("Critical Error: Failed to switch back to menu state: " + switchErr);
            }
        }
    }
}

#end
