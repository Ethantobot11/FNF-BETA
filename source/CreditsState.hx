package;

import citro.CitroG;
import citro.state.CitroState;
import citro.object.CitroSprite;
import citro.object.CitroText;
import citro.math.CitroMath;
import citro.backend.CitroColor;
import sys.FileSystem;
import sys.io.File;

using StringTools;

class CreditsState extends MusicBeatState
{
	var curSelected:Int = -1;
	private var grpOptions:Array<Alphabet> = [];
	private var iconArray:Array<AttachedSprite> = [];
	private var creditsStuff:Array<Array<String>> = [];

	var bg:CitroSprite;
	var descText:CitroText;
	var intendedColor:Int;
	var colorTweenTarget:Int;
	var colorLerp:Float = 0;
	var descBox:AttachedSprite;
	var offsetThing:Float = -75;

	override function create():Void {
		persistentUpdate = true;
		bg = new CitroSprite();
		bg.loadGraphic(Paths.image('menuDesat'));
		bg.screenCenter();
		CitroG.state.members.push(bg);
		
		#if MODS_ALLOWED
		var path:String = 'modsList.txt';
		if(FileSystem.exists(path)) {
			var leMods:Array<String> = CoolUtil.coolTextFile(path);
			for (i in 0...leMods.length) {
				if(leMods.length > 1 && leMods[0].length > 0) {
					var modSplit:Array<String> = leMods[i].split('|');
					if(!Paths.ignoreModFolders.contains(modSplit[0].toLowerCase()) && !modsAdded.contains(modSplit[0])) {
						if(modSplit[1] == '1') pushModCreditsToList(modSplit[0]);
						else modsAdded.push(modSplit[0]);
					}
				}
			}
		}
		var arrayOfFolders:Array<String> = Paths.getModDirectories();
		arrayOfFolders.push('');
		for (folder in arrayOfFolders) pushModCreditsToList(folder);
		#end

		var pisspoop:Array<Array<String>> = [
			['Psych Engine Team'],
			['Shadow Mario', 'shadowmario', 'Main Programmer of Psych Engine', 'https://twitter.com/Shadow_Mario_', '444444'],
			['RiverOaken', 'river', 'Main Artist/Animator of Psych Engine', 'https://twitter.com/RiverOaken', 'B42F71'],
			['shubs', 'shubs', 'Additional Programmer of Psych Engine', 'https://twitter.com/yoshubs', '5E99DF'],
			[''],
			['Former Engine Members'],
			['bb-panzu', 'bb', 'Ex-Programmer of Psych Engine', 'https://twitter.com/bbsub3', '3E813A'],
			[''],
			['Engine Contributors'],
			['iFlicky', 'flicky', 'Composer of Psync and Tea Time', 'https://twitter.com/flicky_i', '9E29CF'],
			['SqirraRNG', 'sqirra', 'Crash Handler and Base code', 'https://twitter.com/gedehari', 'E1843A'],
			['EliteMasterEric', 'mastereric', 'Runtime Shaders support', 'https://twitter.com/EliteMasterEric', 'FFBD40'],
			['PolybiusProxy', 'proxy', '.MP4 Video Loader Library', 'https://twitter.com/polybiusproxy', 'DCD294'],
			['KadeDev', 'kade', 'Fixed cool stuff on Chart Editor', 'https://twitter.com/kade0912', '64A250'],
			['Keoiki', 'keoiki', 'Note Splash Animations', 'https://twitter.com/Keoiki_', 'D2D2D2'],
			['Nebula the Zorua', 'nebula', 'LUA JIT Fork', 'https://twitter.com/Nebula_Zorua', '7D40B2'],
			['Smokey', 'smokey', 'Sprite Atlas Support', 'https://twitter.com/Smokey_5_', '483D92'],
			[''],
			["Funkin' Crew"],
			['ninjamuffin99', 'ninjamuffin99', "Programmer of Friday Night Funkin'", 'https://twitter.com/ninja_muffin99', 'CF2D2D'],
			['PhantomArcade', 'phantomarcade', "Animator of Friday Night Funkin'", 'https://twitter.com/PhantomArcade3K', 'FADC45'],
			['evilsk8r', 'evilsk8r', "Artist of Friday Night Funkin'", 'https://twitter.com/evilsk8r', '5ABD4B'],
			['kawaisprite', 'kawaisprite', "Composer of Friday Night Funkin'", 'https://twitter.com/kawaisprite', '378FC7']
		];
		for(i in pisspoop) creditsStuff.push(i);
	
		for (i in 0...creditsStuff.length) {
			var isSelectable:Bool = !unselectableCheck(i);
			var optionText:Alphabet = new Alphabet(CitroG.WIDTH / 2, 300, creditsStuff[i][0], !isSelectable);
			optionText.isMenuItem = true;
			optionText.targetY = i;
			optionText.changeX = false;
			optionText.snapToPosition();
			grpOptions.push(optionText);
			CitroG.state.members.push(optionText);

			if(isSelectable) {
				if(creditsStuff[i].length > 5 && creditsStuff[i][5] != null) Paths.currentModDirectory = creditsStuff[i][5];
				var icon:AttachedSprite = new AttachedSprite('credits/' + creditsStuff[i][1]);
				icon.xAdd = optionText.width + 10;
				icon.sprTracker = optionText;
				iconArray.push(icon);
				CitroG.state.members.push(icon);
				Paths.currentModDirectory = '';
				if(curSelected == -1) curSelected = i;
			} else {
				optionText.alignment = CENTER;
			}
		}
		
		descBox = new AttachedSprite();
		descBox.makeGraphic(1, 1, CitroColor.BLACK);
		descBox.xAdd = -10; descBox.yAdd = -10;
		descBox.alphaMult = 0.6; descBox.alpha = 0.6;
		CitroG.state.members.push(descBox);

		descText = new CitroText(50, CitroG.HEIGHT + offsetThing - 25, "");
		descText.alignment = CENTER;
		descBox.sprTracker = descText;
		CitroG.state.members.push(descText);

		bg.color = getCurrentBGColor();
		intendedColor = bg.color;
		colorTweenTarget = bg.color;
		changeSelection();
		super.create();
	}

	var quitting:Bool = false;
	var holdTime:Float = 0;
	override function update(delta:Int):Void {
		var elapsed:Float = delta / 1000.0;

		if(!quitting) {
			if(creditsStuff.length > 1) {
				var shiftMult:Int = 1;
				if (controls.UI_UP_P) { changeSelection(-shiftMult); holdTime = 0; }
				if (controls.UI_DOWN_P) { changeSelection(shiftMult); holdTime = 0; }

				if(controls.UI_DOWN || controls.UI_UP) {
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);
					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0) {
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
					}
				}
			}

			if (controls.BACK) {
				SoundPlayer.playSound(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
				quitting = true;
			}
		}
		
		// Manual color lerp
		if (bg.color != colorTweenTarget) {
			colorLerp += elapsed * 2;
			if (colorLerp >= 1) colorLerp = 1;
			var c1 = bg.color, c2 = colorTweenTarget;
			var r = Math.round(((c1 >> 16) & 0xFF) + (((c2 >> 16) & 0xFF) - ((c1 >> 16) & 0xFF)) * colorLerp);
			var g = Math.round(((c1 >> 8) & 0xFF) + (((c2 >> 8) & 0xFF) - ((c1 >> 8) & 0xFF)) * colorLerp);
			var b = Math.round((c1 & 0xFF) + ((c2 & 0xFF) - (c1 & 0xFF)) * colorLerp);
			bg.color = (0xFF << 24) | (r << 16) | (g << 8) | b;
		}

		for (item in grpOptions) {
			if(!item.bold) {
				var lerpVal:Float = CitroMath.clamp(elapsed * 12, 0, 1);
				if(item.targetY == 0) {
					var lastX:Float = item.x;
					item.screenCenter(X);
					item.x = CitroMath.lerp(lastX, item.x - 70, lerpVal);
				} else {
					item.x = CitroMath.lerp(item.x, 200 + -40 * Math.abs(item.targetY), lerpVal);
				}
			}
		}
		super.update(delta);
	}

	function changeSelection(change:Int = 0):Void {
		SoundPlayer.playSound(Paths.sound('scrollMenu'));
		do {
			curSelected += change;
			if (curSelected < 0) curSelected = creditsStuff.length - 1;
			if (curSelected >= creditsStuff.length) curSelected = 0;
		} while(unselectableCheck(curSelected));

		var newColor:Int = getCurrentBGColor();
		if(newColor != intendedColor) {
			intendedColor = newColor;
			colorTweenTarget = newColor;
			colorLerp = 0;
		}

		var bullShit:Int = 0;
		for (item in grpOptions) {
			item.targetY = bullShit - curSelected;
			bullShit++;
			if(!unselectableCheck(bullShit-1)) {
				item.alpha = 0.6;
				if (item.targetY == 0) item.alpha = 1;
			}
		}
		descText.text = creditsStuff[curSelected].length > 2 ? creditsStuff[curSelected][2] : "";
	}

	#if MODS_ALLOWED
	private var modsAdded:Array<String> = [];
	function pushModCreditsToList(folder:String):Void {
		if(modsAdded.contains(folder)) return;
		var creditsFile:String = (folder != null && folder.trim().length > 0) ? Paths.mods(folder + '/data/credits.txt') : Paths.mods('data/credits.txt');
		if (FileSystem.exists(creditsFile)) {
			var firstarray:Array<String> = File.getContent(creditsFile).split('\n');
			for(i in firstarray) {
				var arr:Array<String> = i.replace('\\n', '\n').split("::");
				if(arr.length >= 5) arr.push(folder);
				creditsStuff.push(arr);
			}
			creditsStuff.push(['']);
		}
		modsAdded.push(folder);
	}
	#end

	function getCurrentBGColor():Int {
		if (creditsStuff[curSelected].length > 4) {
			var bgColor:String = creditsStuff[curSelected][4];
			if(!bgColor.startsWith('0x')) bgColor = '0xFF' + bgColor;
			return Std.parseInt(bgColor);
		}
		return 0xFF665AFF;
	}

	private function unselectableCheck(num:Int):Bool {
		return creditsStuff[num].length <= 1;
	}
}


