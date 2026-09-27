package;

import sys.io.File;
import sys.FileSystem;
import haxe.Json;

using StringTools;
class Paths {
	inline public static var SOUND_EXT = "cwav";
	inline public static var VIDEO_EXT = "mp4";

	public static var ignoreModFolders:Array<String> = [
		'characters', 'custom_events', 'custom_notetypes', 'data', 'songs',
		'music', 'sounds', 'shaders', 'videos', 'images', 'stages', 'weeks',
		'fonts', 'scripts', 'achievements'
	];

	public static var dumpExclusions:Array<String> = [];
	public static function excludeAsset(key:String) {
		if (!dumpExclusions.contains(key)) dumpExclusions.push(key);
	}

	public static function clearUnusedMemory() {
		cpp.vm.Gc.run(true);
	}

	public static var localTrackedAssets:Array<String> = [];
	public static function clearStoredMemory(?cleanUnused:Bool = false) {
		localTrackedAssets = [];
	}

	static public var currentModDirectory:String = '';
	static public var currentLevel:String;
	static public function setCurrentLevel(name:String) {
		currentLevel = name.toLowerCase();
	}

	public static function getPath(file:String, type:String, ?library:Null<String> = null):String {
		if (library != null) return getLibraryPath(file, library);

		if (currentLevel != null) {
			var levelPath:String = '';
			if(currentLevel != 'shared') {
				levelPath = getLibraryPathForce(file, currentLevel);
				if (FileSystem.exists(levelPath)) return levelPath;
			}
			levelPath = getLibraryPathForce(file, "shared");
			if (FileSystem.exists(levelPath)) return levelPath;
		}
		return getPreloadPath(file);
	}

	static public function getLibraryPath(file:String, library = "preload"):String {
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String):String {
		return 'romfs:/assets/$library/$file';
	}

	inline public static function getPreloadPath(file:String = ''):String {
		return 'romfs:/assets/$file'; 
	}

	inline static public function file(file:String, type:String = "TEXT", ?library:String):String {
		return getPath(file, type, library);
	}

	inline static public function txt(key:String, ?library:String):String return getPath('data/$key.txt', "TEXT", library);
	inline static public function xml(key:String, ?library:String):String return getPath('data/$key.xml', "TEXT", library);
	inline static public function json(key:String, ?library:String):String return getPath('data/$key.json', "TEXT", library);
	inline static public function shaderFragment(key:String, ?library:String):String return getPath('shaders/$key.frag', "TEXT", library);
	inline static public function shaderVertex(key:String, ?library:String):String return getPath('shaders/$key.vert', "TEXT", library);
	inline static public function lua(key:String, ?library:String):String return getPath('$key.lua', "TEXT", library);

	static public function video(key:String):String {
		#if MODS_ALLOWED
		var file:String = modsVideo(key);
		if(FileSystem.exists(file)) return file;
		#end
		return 'romfs:/assets/videos/$key.$VIDEO_EXT';
	}

	// Returns file path for Citro's SoundPlayer or native audio loading
	static public function sound(key:String, ?library:String):String {
		return returnSoundPath('sounds', key, library);
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String):String {
		return sound(key + Std.random(max - min + 1) + min, library);
	}

	inline static public function music(key:String, ?library:String):String {
		return returnSoundPath('music', key, library);
	}

	inline static public function voices(song:String):String {
		var songKey:String = '${formatToSongPath(song)}/Voices';
		return returnSoundPath('songs', songKey);
	}

	inline static public function inst(song:String):String {
		var songKey:String = '${formatToSongPath(song)}/Inst';
		return returnSoundPath('songs', songKey);
	}

	// Returns image path for CitroSprite.loadGraphic()
	inline static public function image(key:String, ?library:String):String {
		return returnGraphicPath(key, library);
	}

	// Returns .cea path for CitroAnimate (Replaces Sparrow XML)
	inline static public function cea(key:String, ?library:String):String {
		#if MODS_ALLOWED
		var ceaPath = modFolders('images/$key.cea');
		if(FileSystem.exists(ceaPath)) return ceaPath;
		#end
		return getPath('images/$key.cea', "TEXT", library);
	}

	static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String {
		#if sys
		#if MODS_ALLOWED
		if (!ignoreMods && FileSystem.exists(modFolders(key)))
			return File.getContent(modFolders(key));
		#end

		if (FileSystem.exists(getPreloadPath(key)))
			return File.getContent(getPreloadPath(key));

		if (currentLevel != null) {
			var levelPath:String = '';
			if(currentLevel != 'shared') {
				levelPath = getLibraryPathForce(key, currentLevel);
				if (FileSystem.exists(levelPath)) return File.getContent(levelPath);
			}
			levelPath = getLibraryPathForce(key, 'shared');
			if (FileSystem.exists(levelPath)) return File.getContent(levelPath);
		}
		#end
		return File.getContent(getPath(key, "TEXT"));
	}

	inline static public function font(key:String):String {
		#if MODS_ALLOWED
		var file:String = modsFont(key);
		if(FileSystem.exists(file)) return file;
		#end
		return 'romfs:/assets/fonts/$key';
	}

	inline static public function fileExists(key:String, type:String, ?ignoreMods:Bool = false, ?library:String):Bool {
		#if MODS_ALLOWED
		if(FileSystem.exists(mods(currentModDirectory + '/' + key)) || FileSystem.exists(mods(key))) {
			return true;
		}
		#end
		return FileSystem.exists(getPath(key, type));
	}

	inline static public function formatToSongPath(path:String):String {
		var invalidChars = ~/[~&\\;:<>#]/;
		var hideChars = ~/[.,'"%?!]/;
		var p = invalidChars.split(path.replace(' ', '-')).join("-");
		return hideChars.split(p).join("").toLowerCase();
	}

	public static function returnGraphicPath(key:String, ?library:String):String {
		#if MODS_ALLOWED
		var modKey:String = modsImages(key);
		if(FileSystem.exists(modKey)) {
			localTrackedAssets.push(modKey);
			return modKey;
		}
		#end
		var path = getPath('images/$key.png', "IMAGE", library);
		if (FileSystem.exists(path)) {
			localTrackedAssets.push(path);
			return path;
		}
		trace('oh no its returning null NOOOO for image: $key');
		return null;
	}

	public static function returnSoundPath(path:String, key:String, ?library:String):String {
		#if MODS_ALLOWED
		var file:String = modsSounds(path, key);
		if(FileSystem.exists(file)) {
			localTrackedAssets.push(file);
			return file;
		}
		#end
		var gottenPath:String = getPath('$path/$key.$SOUND_EXT', "SOUND", library);
		localTrackedAssets.push(gottenPath);
		return gottenPath;
	}

	#if MODS_ALLOWED
	inline static public function mods(key:String = ''):String return 'mods/' + key;
	inline static public function modsFont(key:String):String return modFolders('fonts/' + key);
	inline static public function modsJson(key:String):String return modFolders('data/' + key + '.json');
	inline static public function modsVideo(key:String):String return modFolders('videos/' + key + '.' + VIDEO_EXT);
	inline static public function modsSounds(path:String, key:String):String return modFolders(path + '/' + key + '.' + SOUND_EXT);
	inline static public function modsImages(key:String):String return modFolders('images/' + key + '.png');

	static public function modFolders(key:String):String {
		if(currentModDirectory != null && currentModDirectory.length > 0) {
			var fileToCheck:String = mods(currentModDirectory + '/' + key);
			if(FileSystem.exists(fileToCheck)) return fileToCheck;
		}
		for(mod in getGlobalMods()){
			var fileToCheck:String = mods(mod + '/' + key);
			if(FileSystem.exists(fileToCheck)) return fileToCheck;
		}
		return 'mods/' + key;
	}

	public static var globalMods:Array<String> = [];
	static public function getGlobalMods():Array<String> return globalMods;

	static public function pushGlobalMods():Array<String> {
		globalMods = [];
		var path:String = 'modsList.txt';
		if(FileSystem.exists(path)) {
			var list:Array<String> = CoolUtil.coolTextFile(path);
			for (i in list) {
				var dat = i.split("|");
				if (dat[1] == "1") {
					var folder = dat[0];
					var mPath = Paths.mods(folder + '/pack.json');
					if(FileSystem.exists(mPath)) {
						try {
							var rawJson:String = File.getContent(mPath);
							if(rawJson != null && rawJson.length > 0) {
								var stuff:Dynamic = Json.parse(rawJson);
								var global:Bool = Reflect.getProperty(stuff, "runsGlobally");
								if(global) globalMods.push(dat[0]);
							}
						} catch(e:Dynamic) { trace(e); }
					}
				}
			}
		}
		return globalMods;
	}
	#end
}