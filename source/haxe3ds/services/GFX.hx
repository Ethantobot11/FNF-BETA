package haxe3ds.services;

import haxe.Log;

@:headerInclude("3ds.h")
class GFX {
	public static inline extern function init() {
		untyped __cpp__('gfxInitDefault()');

		// Save the previous trace function (e.g., from CrashHandler)
		var previousTrace = Log.trace;
		
		Log.trace = (v, ?infos) -> {
			final str = Log.formatOutput(v, infos);
			Sys.println(str);
			SVC.debugString(str);
			
			// Call the previous trace function so CrashHandler still gets the data!
			if (previousTrace != null) {
				previousTrace(v, infos);
			}
		};
	}

	public static var current3D(get, set):Bool;
	static function get_current3D():Bool {
		return untyped __cpp__('gfxIs3D()');
	}
	static function set_current3D(current3D):Bool {
		untyped __cpp__('gfxSet3D(current3D)');
		return current3D;
	}

	public static var isWide(get, set):Bool;
	static function get_isWide():Bool {
		return untyped __cpp__('gfxIsWide()');
	}
	static function set_isWide(isWide):Bool {
		untyped __cpp__('gfxSetWide(isWide)');
		return isWide;
	}

	public static inline extern function exit() {
		untyped __cpp__('gfxExit()');
	}
}