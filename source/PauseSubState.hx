package;

import citro.CitroG;
import citro.state.CitroSubState;
import citro.object.CitroSprite;
import citro.object.CitroText;
import citro.backend.CitroColor;
import citro.backend.CitroTween;
import GameplayChangersSubstate;

using StringTools;

class PauseSubState extends MusicBeatSubstate
{
	var grpMenuShit:Array<Alphabet> = [];

	var menuItems:Array<String> = [];
	var menuItemsOG:Array<String> = ['Resume', 'Restart Song', 'Change Difficulty', 'Options', 'Exit to menu'];
	var difficultyChoices:Array<String> = [];
	var curSelected:Int = 0;

	var curTime:Float = 0;
	var skipTimeText:CitroText;
	var skipTimeTracker:Alphabet;

	public static var songName:String = '';

	public function new(x:Float, y:Float)
	{
		super();
		if(CoolUtil.difficulties.length < 2) menuItemsOG.remove('Change Difficulty');

		if(PlayState.chartingMode)
		{
			menuItemsOG.insert(2, 'Leave Charting Mode');
			var num:Int = 0;
			if(!PlayState.instance.startingSong)
			{
				num = 1;
				menuItemsOG.insert(3, 'Skip Time');
			}
			menuItemsOG.insert(3 + num, 'End Song');
			menuItemsOG.insert(4 + num, 'Toggle Practice Mode');
			menuItemsOG.insert(5 + num, 'Toggle Botplay');
		}
		menuItems = menuItemsOG.copy();

		for (i in 0...CoolUtil.difficulties.length) {
			difficultyChoices.push(CoolUtil.difficulties[i]);
		}
		difficultyChoices.push('BACK');

		// Play pause music (Assumes your SoundPlayer can handle music paths, or stubs gracefully)
		if(songName != null && songName != '') {
			SoundPlayer.playSound(Paths.music(songName));
		} else if (ClientPrefs.pauseMusic != 'None') {
			SoundPlayer.playSound(Paths.music(Paths.formatToSongPath(ClientPrefs.pauseMusic)));
		}

		var bg:CitroSprite = new CitroSprite().makeGraphic(CitroG.WIDTH, CitroG.HEIGHT, CitroColor.BLACK);
		bg.alpha = 0;
		this.members.push(bg);

		var levelInfo:CitroText = new CitroText(20, 15, PlayState.SONG.song);
		levelInfo.alignment = RIGHT;
		this.members.push(levelInfo);

		var levelDifficulty:CitroText = new CitroText(20, 15 + 32, CoolUtil.difficultyString());
		levelDifficulty.alignment = RIGHT;
		this.members.push(levelDifficulty);

		var blueballedTxt:CitroText = new CitroText(20, 15 + 64, "Blueballed: " + PlayState.deathCounter);
		blueballedTxt.alignment = RIGHT;
		this.members.push(blueballedTxt);

		var practiceText:CitroText = new CitroText(20, 15 + 101, "PRACTICE MODE");
		practiceText.alignment = RIGHT;
		practiceText.visible = PlayState.instance.practiceMode;
		this.members.push(practiceText);

		var chartingText:CitroText = new CitroText(20, CitroG.HEIGHT - 50, "CHARTING MODE");
		chartingText.alignment = RIGHT;
		chartingText.visible = PlayState.chartingMode;
		this.members.push(chartingText);

		// Fade in tweens
		var propsBg = new Map<String, Float>();
		propsBg.set("alpha", 0.6);
		CitroTween.tweenObject(bg, propsBg, 0.4);

		var propsInfo = new Map<String, Float>();
		propsInfo.set("alpha", 1);
		propsInfo.set("y", 20);
		CitroTween.tweenObject(levelInfo, propsInfo, 0.4);

		var propsDiff = new Map<String, Float>();
		propsDiff.set("alpha", 1);
		propsDiff.set("y", levelDifficulty.y + 5);
		CitroTween.tweenObject(levelDifficulty, propsDiff, 0.4);

		var propsBlue = new Map<String, Float>();
		propsBlue.set("alpha", 1);
		propsBlue.set("y", blueballedTxt.y + 5);
		CitroTween.tweenObject(blueballedTxt, propsBlue, 0.4);

		regenMenu();
	}

	var holdTime:Float = 0;
	var cantUnpause:Float = 0.1;

	override public function update(delta:Int):Void {
		var elapsed:Float = delta / 1000.0;
		cantUnpause -= elapsed;

		super.update(delta);
		updateSkipTextStuff();

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;

		if (upP) changeSelection(-1);
		if (downP) changeSelection(1);

		var daSelected:String = menuItems[curSelected];
		switch (daSelected)
		{
			case 'Skip Time':
				if (controls.UI_LEFT_P) {
					SoundPlayer.playSound(Paths.sound('scrollMenu'));
					curTime -= 1000;
					holdTime = 0;
				}
				if (controls.UI_RIGHT_P) {
					SoundPlayer.playSound(Paths.sound('scrollMenu'));
					curTime += 1000;
					holdTime = 0;
				}

				if(controls.UI_LEFT || controls.UI_RIGHT) {
					holdTime += elapsed;
					if(holdTime > 0.5) {
						curTime += 45000 * elapsed * (controls.UI_LEFT ? -1 : 1);
					}
					if(curTime >= PlayState.instance.songLength) curTime -= PlayState.instance.songLength;
					else if(curTime < 0) curTime += PlayState.instance.songLength;
					updateSkipTimeText();
				}
		}

		if (accepted && (cantUnpause <= 0 || !ClientPrefs.controllerMode))
		{
			if (menuItems == difficultyChoices)
			{
				if(menuItems.length - 1 != curSelected && difficultyChoices.contains(daSelected)) {
					var name:String = PlayState.SONG.song;
					var poop = Highscore.formatSong(name, curSelected);
					PlayState.SONG = Song.loadFromJson(poop, name);
					PlayState.storyDifficulty = curSelected;
					MusicBeatState.resetState();
					PlayState.changedDifficulty = true;
					PlayState.chartingMode = false;
					return;
				}

				menuItems = menuItemsOG.copy();
				regenMenu();
			}

			switch (daSelected)
			{
				case "Resume":
					closeSub();
				case 'Change Difficulty':
					menuItems = difficultyChoices.copy();
					deleteSkipTimeText();
					regenMenu();
				case 'Options':
					closeSub();
					// Opens the Gameplay Changers menu quickly as a substate
					MusicBeatState.switchState(new options.OptionsState());
				case "Restart Song":
					restartSong();
				case "Leave Charting Mode":
					restartSong();
					PlayState.chartingMode = false;
				case 'Skip Time':
					if(curTime < Conductor.songPosition) {
						PlayState.startOnTime = curTime;
						restartSong(true);
					} else {
						if (curTime != Conductor.songPosition) {
							PlayState.instance.clearNotesBefore(curTime);
							PlayState.instance.setSongTime(curTime);
						}
						closeSub();
					}
				case "End Song":
					closeSub();
					PlayState.instance.finishSong(true);
				case 'Toggle Practice Mode':
					PlayState.instance.practiceMode = !PlayState.instance.practiceMode;
					PlayState.changedDifficulty = true;
				case 'Toggle Botplay':
					PlayState.instance.cpuControlled = !PlayState.instance.cpuControlled;
					PlayState.changedDifficulty = true;
				case "Exit to menu":
					PlayState.deathCounter = 0;
					PlayState.seenCutscene = false;
					WeekData.loadTheFirstEnabledMod();
					if(PlayState.isStoryMode) {
						MusicBeatState.switchState(new StoryMenuState());
					} else {
						MusicBeatState.switchState(new FreeplayState());
					}
					PlayState.cancelMusicFadeTween();
					PlayState.changedDifficulty = false;
					PlayState.chartingMode = false;
			}
		}
	}

	function closeSub():Void {
		CitroG.substate = null;
        if (PlayState.instance != null) {
			PlayState.instance.paused = false;
			PlayState.instance.persistentUpdate = true;
			PlayState.instance.persistentDraw = true;
		}
	}

	function deleteSkipTimeText() {
		if(skipTimeText != null) {
			this.members.remove(skipTimeText);
			skipTimeText.destroy();
		}
		skipTimeText = null;
		skipTimeTracker = null;
	}

	public static function restartSong(noTrans:Bool = false) {
		PlayState.instance.paused = true;
		if(noTrans) {
			MusicBeatState.switchState(new PlayState());
		} else {
			MusicBeatState.resetState();
		}
	}

	override public function destroy():Void {
		super.destroy();
	}

	function changeSelection(change:Int = 0):Void {
		curSelected += change;
		SoundPlayer.playSound(Paths.sound('scrollMenu'));

		if (curSelected < 0) curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length) curSelected = 0;

		var bullShit:Int = 0;
		for (item in grpMenuShit) {
			item.targetY = bullShit - curSelected;
			bullShit++;
			item.alpha = 0.6;

			if (item.targetY == 0) {
				item.alpha = 1;
				if(item == skipTimeTracker) {
					curTime = Math.max(0, Conductor.songPosition);
					updateSkipTimeText();
				}
			}
		}
	}

	function regenMenu():Void {
		while(grpMenuShit.length > 0) {
			var obj = grpMenuShit.shift();
			this.members.remove(obj);
			obj.destroy();
		}

		for (i in 0...menuItems.length) {
			var item = new Alphabet(90, 320, menuItems[i], true);
			item.isMenuItem = true;
			item.targetY = i;
			grpMenuShit.push(item);
			this.members.push(item);

			if(menuItems[i] == 'Skip Time') {
				skipTimeText = new CitroText(0, 0, '');
				skipTimeText.alignment = LEFT;
				skipTimeTracker = item;
				this.members.push(skipTimeText);
				updateSkipTextStuff();
				updateSkipTimeText();
			}
		}
		curSelected = 0;
		changeSelection();
	}
	
	function updateSkipTextStuff() {
		if(skipTimeText == null || skipTimeTracker == null) return;
		skipTimeText.x = skipTimeTracker.x + skipTimeTracker.width + 60;
		skipTimeText.y = skipTimeTracker.y;
		skipTimeText.visible = (skipTimeTracker.alpha >= 1);
	}

	function updateSkipTimeText() {
		var curSec = Math.floor(Math.max(0, curTime / 1000));
		var totalSec = Math.floor(Math.max(0, PlayState.instance.songLength / 1000));
		skipTimeText.text = formatTime(curSec) + ' / ' + formatTime(totalSec);
	}

	function formatTime(seconds:Int):String {
		var min = Math.floor(seconds / 60);
		var sec = seconds % 60;
		return (min < 10 ? "0" : "") + min + ":" + (sec < 10 ? "0" : "") + sec;
	}
}