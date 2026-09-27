package;

import sys.io.File;
import sys.FileSystem;
import haxe.Json;

using StringTools;

typedef WeekFile = {
	var songs:Array<Dynamic>;
	var weekCharacters:Array<String>;
	var weekBackground:String;
	var weekBefore:String;
	var storyName:String;
	var weekName:String;
	var freeplayColor:Array<Int>;
	var startUnlocked:Bool;
	var hiddenUntilUnlocked:Bool;
	var hideStoryMode:Bool;
	var hideFreeplay:Bool;
	var difficulties:String;
}

class WeekData {
	public static var weeksLoaded:Map<String, WeekData> = new Map<String, WeekData>();
	public static var weeksList:Array<String> = [];
	public var folder:String = '';
	
	public var songs:Array<Dynamic>;
	public var weekCharacters:Array<String>;
	public var weekBackground:String;
	public var weekBefore:String;
	public var storyName:String;
	public var weekName:String;
	public var freeplayColor:Array<Int>;
	public var startUnlocked:Bool;
	public var hiddenUntilUnlocked:Bool;
	public var hideStoryMode:Bool;
	public var hideFreeplay:Bool;
	public var difficulties:String;
	public var fileName:String;

	public static function createWeekFile():WeekFile {
		return {
			songs: [["Bopeebo", "dad", [146, 113, 253]], ["Fresh", "dad", [146, 113, 253]], ["Dad Battle", "dad", [146, 113, 253]]],
			weekCharacters: ['dad', 'bf', 'gf'],
			weekBackground: 'stage',
			weekBefore: 'tutorial',
			storyName: 'Your New Week',
			weekName: 'Custom Week',
			freeplayColor: [146, 113, 253],
			startUnlocked: true,
			hiddenUntilUnlocked: false,
			hideStoryMode: false,
			hideFreeplay: false,
			difficulties: ''
		};
	}

	public function new(weekFile:WeekFile, fileName:String) {
		songs = weekFile.songs;
		weekCharacters = weekFile.weekCharacters;
		weekBackground = weekFile.weekBackground;
		weekBefore = weekFile.weekBefore;
		storyName = weekFile.storyName;
		weekName = weekFile.weekName;
		freeplayColor = weekFile.freeplayColor;
		startUnlocked = weekFile.startUnlocked;
		hiddenUntilUnlocked = weekFile.hiddenUntilUnlocked;
		hideStoryMode = weekFile.hideStoryMode;
		hideFreeplay = weekFile.hideFreeplay;
		difficulties = weekFile.difficulties;
		this.fileName = fileName;
	}

	public static function reloadWeekFiles(isStoryMode:Null<Bool> = false) {
		weeksList = [];
		weeksLoaded.clear();
		
		var directories:Array<String> = [Paths.getPreloadPath()];
		#if MODS_ALLOWED
		directories.push(Paths.mods());
		// Add mod directory parsing logic here if needed
		#end

		for (dir in directories) {
			var weekListPath = dir + 'weeks/weekList.txt';
			if(FileSystem.exists(weekListPath)) {
				var sexList:Array<String> = CoolUtil.coolTextFile(weekListPath);
				for (i in 0...sexList.length) {
					var fileToCheck:String = dir + 'weeks/' + sexList[i] + '.json';
					if(!weeksLoaded.exists(sexList[i])) {
						var week:WeekFile = getWeekFile(fileToCheck);
						if(week != null) {
							var weekFile:WeekData = new WeekData(week, sexList[i]);
							if(weekFile != null && (isStoryMode == null || (isStoryMode && !weekFile.hideStoryMode) || (!isStoryMode && !weekFile.hideFreeplay))) {
								weeksLoaded.set(sexList[i], weekFile);
								weeksList.push(sexList[i]);
							}
						}
					}
				}
			}
		}
	}

	private static function getWeekFile(path:String):WeekFile {
		var rawJson:String = null;
		if(FileSystem.exists(path)) {
			rawJson = File.getContent(path);
		}
		if(rawJson != null && rawJson.length > 0) {
			return cast Json.parse(rawJson);
		}
		return null;
	}

	public static function getWeekFileName():String {
		return weeksList[PlayState.storyWeek];
	}

	public static function getCurrentWeek():WeekData {
		return weeksLoaded.get(weeksList[PlayState.storyWeek]);
	}

	public static function setDirectoryFromWeek(?data:WeekData = null) {
		Paths.currentModDirectory = '';
		if(data != null && data.folder != null && data.folder.length > 0) {
			Paths.currentModDirectory = data.folder;
		}
	}

	public static function loadTheFirstEnabledMod() {
		Paths.currentModDirectory = '';
		#if MODS_ALLOWED
		if (FileSystem.exists("modsList.txt")) {
			var list:Array<String> = CoolUtil.listFromString(File.getContent("modsList.txt"));
			var foundTheTop = false;
			for (i in list) {
				var dat = i.split("|");
				if (dat[1] == "1" && !foundTheTop) {
					foundTheTop = true;
					Paths.currentModDirectory = dat[0];
				}
			}
		}
		#end
	}
}