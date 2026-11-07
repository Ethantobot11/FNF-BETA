package citro;

#if (!wiiu || !cafe)

import haxe.Json;
import haxe3ds.services.FS;
import sys.FileSystem;
import sys.io.File;

enum CitroSaveStatus {
	SUCCESSFUL;
	FS_ERROR;
	USES_3DSX;
}

class CitroSave {
	public var status(default, null):CitroSaveStatus;
	public var data:Dynamic = {};
	private var savePath:String = "sdmc:/DELTASHIT/save.json";

	public function new(files:Int = 16, dirs:Int = 1) {
		#if IS_3DSX
		status = USES_3DSX;
		trace("Warning: Saves are not supported in 3DSX mode. Use CIA.");
		#else
		if (FS.mountSaveData("sdmc", files, dirs).isFail()) {
			status = FS_ERROR;
			trace("Error: Failed to mount Save Data.");
			return;
		}

		if (FileSystem.exists(savePath)) {
			try {
				var content = File.getContent(savePath);
				if (content != null && content.length > 0) {
					data = Json.parse(content);
				}
			} catch (e:Dynamic) {
				trace("Error parsing save file, resetting: " + e);
				FileSystem.deleteFile(savePath);
				data = {};
			}
		}
		status = SUCCESSFUL;
		#end
	}

	public function flush():Bool {
		if (status != SUCCESSFUL) return false;

		try {
			File.saveContent(savePath, Json.stringify(data));
			FS.flushAndCommit();
			return true;
		} catch (e:Dynamic) {
			trace("Failed to flush save: " + e);
			return false;
		}
	}

	public function delete(alsoResetData:Bool = true):Bool {
		if (status != SUCCESSFUL) return false;

		if (alsoResetData) data = {};

		try {
			if (FileSystem.exists(savePath)) {
				FileSystem.deleteFile(savePath);
			}
			FS.flushAndCommit();
			return true;
		} catch (e:Dynamic) {
			return false;
		}
	}
}
#end
