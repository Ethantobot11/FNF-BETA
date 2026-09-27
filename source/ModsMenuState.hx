package;

import citro.CitroG;
import citro.object.CitroSprite;
import citro.object.CitroText;
import citro.math.CitroMath;
import citro.backend.CitroColor;
import sys.io.File;
import sys.FileSystem;
import haxe.Json;

using StringTools;

class ModsMenuState extends MusicBeatState
{
	var mods:Array<ModMetadata> = [];
	static var changedAThing = false;
	var bg:CitroSprite;
	var intendedColor:CitroColor;

	var noModsTxt:CitroText;
	var selector:CitroSprite;
	var descriptionTxt:CitroText;
	var needaReset = false;
	private static var curSelected:Int = 0;
	public static var defaultColor:CitroColor = 0xFF665AFF;

	var modsList:Array<Dynamic> = [];
	var visibleWhenNoMods:Array<Dynamic> = [];
	var visibleWhenHasMods:Array<Dynamic> = [];

	override function create():Void {
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		WeekData.setDirectoryFromWeek();

		bg = new CitroSprite();
		bg.loadGraphic(Paths.image('menuDesat'));
		bg.screenCenter();
		CitroG.state.members.push(bg);

		noModsTxt = new CitroText(0, 0, "NO MODS INSTALLED\nPRESS B TO EXIT AND INSTALL A MOD");
		noModsTxt.alignment = CENTER;
		noModsTxt.screenCenter();
		CitroG.state.members.push(noModsTxt);
		visibleWhenNoMods.push(noModsTxt);

		var path:String = 'sdmc:/FNF-PE/modsList.txt';
		if(FileSystem.exists(path)) {
			var leMods:Array<String> = CoolUtil.coolTextFile(path);
			for (i in 0...leMods.length) {
				if(leMods.length > 1 && leMods[0].length > 0) {
					var modSplit:Array<String> = leMods[i].split('|');
					if(!Paths.ignoreModFolders.contains(modSplit[0].toLowerCase())) {
						addToModsList([modSplit[0], (modSplit[1] == '1')]);
					}
				}
			}
		}

		if (FileSystem.exists("sdmc:/FNF-PE/modsList.txt")) {
			for (folder in Paths.getModDirectories()) {
				if(!Paths.ignoreModFolders.contains(folder)) addToModsList([folder, true]);
			}
	 }
		saveTxt();

		selector = new CitroSprite();
		selector.makeGraphic(1100, 450, CitroColor.BLACK);
		selector.alpha = 0.5;
		CitroG.state.members.push(selector);
		visibleWhenHasMods.push(selector);

		descriptionTxt = new CitroText(148, 0, "");
		descriptionTxt.alignment = LEFT;
		CitroG.state.members.push(descriptionTxt);
		visibleWhenHasMods.push(descriptionTxt);

		var i:Int = 0;
		while (i < modsList.length) {
			var values:Array<Dynamic> = modsList[i];
			if(!FileSystem.exists(Paths.mods(values[0]))) { modsList.remove(modsList[i]); continue; }

			var newMod:ModMetadata = new ModMetadata(values[0]);
			mods.push(newMod);

			newMod.alphabet = new Alphabet(0, 0, mods[i].name, true);
			var scale:Float = Math.min(840 / newMod.alphabet.width, 1);
			newMod.alphabet.scale.set(scale, scale);
			newMod.alphabet.y = i * 150;
			newMod.alphabet.x = 310;
			CitroG.state.members.push(newMod.alphabet);

			newMod.icon = new CitroSprite();
			var iconToUse:String = Paths.mods(values[0] + '/pack.png');
			if(FileSystem.exists(iconToUse)) newMod.icon.loadGraphic(iconToUse);
			else newMod.icon.loadGraphic(Paths.image('unknownMod'));
			
			newMod.icon.x = newMod.alphabet.x - newMod.icon.width - 30;
			newMod.icon.y = newMod.alphabet.y - 45;
			CitroG.state.members.push(newMod.icon);
			i++;
		}

		if(curSelected >= mods.length) curSelected = 0;
		bg.color = mods.length < 1 ? defaultColor : mods[curSelected].color;
		intendedColor = bg.color;
		
		changeSelection();
		updatePosition();
		SoundPlayer.playSound(Paths.sound('scrollMenu'));
		super.create();
	}

	function addToModsList(values:Array<Dynamic>) {
		for (i in 0...modsList.length) if(modsList[i][0] == values[0]) return;
		modsList.push(values);
	}

	function moveMod(change:Int, skipResetCheck:Bool = false) {
		if(mods.length > 1) {
			var doRestart:Bool = mods[0].restart;
			var newPos:Int = curSelected + change;
			if(newPos < 0) { modsList.push(modsList.shift()); mods.push(mods.shift()); }
			else if(newPos >= mods.length) { modsList.insert(0, modsList.pop()); mods.insert(0, mods.pop()); }
			else {
				var lastArray = modsList[curSelected]; modsList[curSelected] = modsList[newPos]; modsList[newPos] = lastArray;
				var lastMod = mods[curSelected]; mods[curSelected] = mods[newPos]; mods[newPos] = lastMod;
			}
			changeSelection(change);
			if(!doRestart) doRestart = mods[curSelected].restart;
			if(!skipResetCheck && doRestart) needaReset = true;
		}
	}

	function saveTxt() {
		var fileStr:String = '';
		for (values in modsList) {
			if(fileStr.length > 0) fileStr += '\n';
			fileStr += values[0] + '|' + (values[1] ? '1' : '0');
		}
		File.saveContent('sdmc:/FNF-PE/modsList.txt', fileStr);
		Paths.pushGlobalMods();
	}

	var noModsSine:Float = 0;
	var canExit:Bool = true;

	override public function update(delta:Int):Void {
		var elapsed:Float = delta / 1000.0;
		if(noModsTxt.visible) {
			noModsSine += 180 * elapsed;
			noModsTxt.alpha = 1 - Math.sin((Math.PI * noModsSine) / 180);
		}

		if(canExit && controls.BACK) {
			SoundPlayer.playSound(Paths.sound('cancelMenu'));
			saveTxt();
			if(needaReset) {
				TitleState.initialized = false;
				TitleState.closedState = false;
				MusicBeatState.switchState(new TitleState());
			} else {
				MusicBeatState.switchState(new MainMenuState());
			}
		}

		if(mods.length > 0) {
			if(controls.UI_UP_P) { changeSelection(-1); SoundPlayer.playSound(Paths.sound('scrollMenu')); }
			if(controls.UI_DOWN_P) { changeSelection(1); SoundPlayer.playSound(Paths.sound('scrollMenu')); }
			
			if(controls.ACCEPT) {
				modsList[curSelected][1] = !modsList[curSelected][1];
				if(mods[curSelected].restart) needaReset = true;
				SoundPlayer.playSound(Paths.sound('scrollMenu'));
			}
			if(controls.UI_LEFT_P) { moveMod(-1); SoundPlayer.playSound(Paths.sound('scrollMenu')); }
			if(controls.UI_RIGHT_P) { moveMod(1); SoundPlayer.playSound(Paths.sound('scrollMenu')); }
			if(controls.PAUSE) {
				moveMod(-curSelected); SoundPlayer.playSound(Paths.sound('scrollMenu'));
			}
			if(controls.RESET) {
				for (i in modsList) i[1] = false;
				for (mod in mods) if(mod.restart) needaReset = true;
				SoundPlayer.playSound(Paths.sound('scrollMenu'));
			}
		}
		updatePosition(elapsed);
		super.update(delta);
	}

	function changeSelection(change:Int = 0) {
		var noMods:Bool = (mods.length < 1);
		for (obj in visibleWhenHasMods) {
			if(Std.isOfType(obj, CitroSprite)) (cast obj:CitroSprite).visible = !noMods;
			else if(Std.isOfType(obj, CitroText)) (cast obj:CitroText).visible = !noMods;
		}
		for (obj in visibleWhenNoMods) (cast obj:CitroSprite).visible = noMods;
		if(noMods) return;

		curSelected += change;
		if(curSelected < 0) curSelected = mods.length - 1;
		else if(curSelected >= mods.length) curSelected = 0;

		var newColor:CitroColor = mods[curSelected].color;
		if(newColor != intendedColor) {
			intendedColor = newColor;
			bg.color = intendedColor;
		}

		var i:Int = 0;
		for (mod in mods) {
			mod.alphabet.alpha = (i == curSelected) ? 1 : 0.6;
			if(i == curSelected) {
				selector.x = mod.alphabet.x - 205;
				selector.y = mod.alphabet.y - 68;
				descriptionTxt.text = mod.description + (mod.restart ? " (This Mod will restart the game!)" : "");
			}
			i++;
		}
	}

	function updatePosition(elapsed:Float = -1) {
		var i:Int = 0;
		for (mod in mods) {
			var intendedPos:Float = (i - curSelected) * 225 + 200;
			if(i > curSelected) intendedPos += 225;
			if(elapsed == -1) mod.alphabet.y = intendedPos;
			else mod.alphabet.y = CitroMath.lerp(mod.alphabet.y, intendedPos, CitroMath.clamp(elapsed * 12, 0, 1));

			if(i == curSelected) {
				descriptionTxt.y = mod.alphabet.y + 160;
			}
			i++;
		}
	}
}

class ModMetadata {
	public var folder:String;
	public var name:String;
	public var description:String;
	public var color:CitroColor;
	public var restart:Bool;
	public var alphabet:Alphabet;
	public var icon:CitroSprite;

	public function new(folder:String) {
		this.folder = folder;
		this.name = folder;
		this.description = "No description provided.";
		this.color = ModsMenuState.defaultColor;
		this.restart = false;

		var path = Paths.mods(folder + '/pack.json');
		if(FileSystem.exists(path)) {
			var rawJson:String = File.getContent(path);
			if(rawJson != null && rawJson.length > 0) {
				var stuff:Dynamic = Json.parse(rawJson);
				var colors:Array<Int> = Reflect.getProperty(stuff, "color");
				var desc:String = Reflect.getProperty(stuff, "description");
				var name:String = Reflect.getProperty(stuff, "name");
				var restart:Bool = Reflect.getProperty(stuff, "restart");

				if(name != null && name.length > 0 && name != 'Name') this.name = name;
				if(desc != null && desc.length > 0 && desc != 'Description') this.description = desc;
				if(colors != null && colors.length > 2) this.color = (0xFF << 24) | (colors[0] << 16) | (colors[1] << 8) | colors[2];
				if(restart != null) this.restart = restart;
			}
		}
	}
}