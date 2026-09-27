package;

import citro.CitroG;
import citro.object.CitroSprite;
import citro.object.CitroText;
import citro.math.CitroMath;
import citro.backend.CitroColor;
import citro.backend.CitroTween;
import citro.backend.CitroTimer;

using StringTools;

class StoryMenuState extends MusicBeatState
{
	public static var weekCompleted:Map<String, Bool> = new Map<String, Bool>();

	var scoreText:CitroText;
	private static var lastDifficultyName:String = '';
	var curDifficulty:Int = 1;

	var txtWeekTitle:CitroText;
	var bgSprite:CitroSprite;

	private static var curWeek:Int = 0;
	var txtTracklist:CitroText;

	var grpWeekText:Array<MenuItem> = [];
	var grpWeekCharacters:Array<MenuCharacter> = [];
	var grpLocks:Array<CitroSprite> = [];

	var difficultySelectors:Array<CitroSprite> = [];
	var sprDifficulty:CitroSprite;
	var leftArrow:CitroSprite;
	var rightArrow:CitroSprite;

	var loadedWeeks:Array<WeekData> = [];

	override function create():Void
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		PlayState.isStoryMode = true;
		WeekData.reloadWeekFiles(true);
		if(curWeek >= WeekData.weeksList.length) curWeek = 0;
		persistentUpdate = true;
		persistentDraw = true;

		scoreText = new CitroText(10, 10, "SCORE: 49324858");
		scoreText.alignment = LEFT;
		CitroG.state.members.push(scoreText);

		txtWeekTitle = new CitroText(400 * 0.7, 10, "");
		txtWeekTitle.alignment = RIGHT;
		txtWeekTitle.alpha = 0.7;
		CitroG.state.members.push(txtWeekTitle);

		var rankText:CitroText = new CitroText(0, 10, 'RANK: GREAT');
		rankText.alignment = CENTER;
		rankText.screenCenter(X);
		CitroG.state.members.push(rankText);

		bgSprite = new CitroSprite(0, 56);
		bgSprite.antialiasing = ClientPrefs.globalAntialiasing;
		CitroG.state.members.push(bgSprite);

		var blackBarThingie:CitroSprite = new CitroSprite().makeGraphic(400, 56, CitroColor.BLACK);
		CitroG.state.members.push(blackBarThingie);

		var num:Int = 0;
		for (i in 0...WeekData.weeksList.length)
		{
			var weekFile:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var isLocked:Bool = weekIsLocked(WeekData.weeksList[i]);
			if(!isLocked || !weekFile.hiddenUntilUnlocked)
			{
				loadedWeeks.push(weekFile);
				WeekData.setDirectoryFromWeek(weekFile);
				var weekThing:MenuItem = new MenuItem(0, bgSprite.y + 396, WeekData.weeksList[i]);
				weekThing.y += ((weekThing.CitroG.HEIGHT + 20) * num);
				weekThing.targetY = num;
				grpWeekText.push(weekThing);
				CitroG.state.members.push(weekThing);

				weekThing.screenCenter(X);

				if (isLocked)
				{
					var lock:CitroSprite = new CitroSprite(weekThing.CitroG.WIDTH + 10 + weekThing.x, weekThing.y);
					lock.loadGraphic(Paths.image('campaign_menu_UI_assets'));
					lock.antialiasing = ClientPrefs.globalAntialiasing;
					grpLocks.push(lock);
					CitroG.state.members.push(lock);
				}
				num++;
			}
		}

		if(loadedWeeks.length > 0) {
			WeekData.setDirectoryFromWeek(loadedWeeks[0]);
			var charArray:Array<String> = loadedWeeks[0].weekCharacters;
			for (char in 0...3)
			{
				if(char < charArray.length) {
					var weekCharacterThing:MenuCharacter = new MenuCharacter((400 * 0.25) * (1 + char) - 150, charArray[char]);
					weekCharacterThing.y += 70;
					grpWeekCharacters.push(weekCharacterThing);
					CitroG.state.members.push(weekCharacterThing);
				}
			}
		}

		leftArrow = new CitroSprite(0, 0);
		leftArrow.loadGraphic(Paths.image('campaign_menu_UI_assets'));
		leftArrow.antialiasing = ClientPrefs.globalAntialiasing;
		difficultySelectors.push(leftArrow);
		CitroG.state.members.push(leftArrow);

		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
		if(lastDifficultyName == '') {
			lastDifficultyName = CoolUtil.defaultDifficulty;
		}
		curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName)));
		
		sprDifficulty = new CitroSprite(0, leftArrow.y);
		sprDifficulty.antialiasing = ClientPrefs.globalAntialiasing;
		difficultySelectors.push(sprDifficulty);
		CitroG.state.members.push(sprDifficulty);

		rightArrow = new CitroSprite(leftArrow.x + 376, leftArrow.y);
		rightArrow.loadGraphic(Paths.image('campaign_menu_UI_assets'));
		rightArrow.antialiasing = ClientPrefs.globalAntialiasing;
		difficultySelectors.push(rightArrow);
		CitroG.state.members.push(rightArrow);

		var bgYellow:CitroSprite = new CitroSprite(0, 56).makeGraphic(400, 386, 0xFFF9CF51);
		CitroG.state.members.push(bgYellow);

		var tracksSprite:CitroSprite = new CitroSprite(400 * 0.07, bgSprite.y + 425).loadGraphic(Paths.image('Menu_Tracks'));
		tracksSprite.antialiasing = ClientPrefs.globalAntialiasing;
		CitroG.state.members.push(tracksSprite);

		txtTracklist = new CitroText(400 * 0.05, tracksSprite.y + 60, "");
		txtTracklist.alignment = CENTER;
		txtTracklist.color = 0xFFe55777;
		CitroG.state.members.push(txtTracklist);

		changeWeek();
		changeDifficulty();

		super.create();
	}

	override function closeSubState():Void {
		persistentUpdate = true;
		changeWeek();
		super.closeSubState();
	}

	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	override function update(delta:Int):Void
	{
		var elapsed:Float = delta / 1000.0;
		lerpScore = Math.floor(CitroMath.lerp(lerpScore, intendedScore, CitroMath.clamp(elapsed * 30, 0, 1)));
		if(Math.abs(intendedScore - lerpScore) < 10) lerpScore = intendedScore;

		scoreText.text = "WEEK SCORE:" + lerpScore;

		if (!movedBack && !selectedWeek)
		{
			if (controls.UI_UP_P) {
				changeWeek(-1);
				SoundPlayer.playSound(Paths.sound('scrollMenu'));
			}
			if (controls.UI_DOWN_P) {
				changeWeek(1);
				SoundPlayer.playSound(Paths.sound('scrollMenu'));
			}

			if (controls.UI_RIGHT_P)
				changeDifficulty(1);
			else if (controls.UI_LEFT_P)
				changeDifficulty(-1);
			else if (controls.UI_UP_P || controls.UI_DOWN_P)
				changeDifficulty();

			if(controls.RESET) {
				persistentUpdate = false;
				openSubState(new ResetScoreSubState('', curDifficulty, '', curWeek));
			}
			else if (controls.ACCEPT) {
				selectWeek();
			}
		}

		if (controls.BACK && !movedBack && !selectedWeek) {
			SoundPlayer.playSound(Paths.sound('cancelMenu'));
			movedBack = true;
			MusicBeatState.switchState(new MainMenuState());
		}

		super.update(delta);

		for (i in 0...grpLocks.length) {
			if(i < grpWeekText.length) {
				grpLocks[i].y = grpWeekText[i].y;
				grpLocks[i].visible = (grpLocks[i].y > 240 / 2);
			}
		}
	}

	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;

	function selectWeek():Void
	{
		if (loadedWeeks.length > 0 && !weekIsLocked(loadedWeeks[curWeek].fileName))
		{
			if (stopspamming == false)
			{
				SoundPlayer.playSound(Paths.sound('confirmMenu'));
				grpWeekText[curWeek].startFlashing();
				stopspamming = true;
			}

			var songArray:Array<String> = [];
			var leWeek:Array<Dynamic> = loadedWeeks[curWeek].songs;
			for (i in 0...leWeek.length) {
				songArray.push(leWeek[i][0]);
			}

			PlayState.storyPlaylist = songArray;
			PlayState.isStoryMode = true;
			selectedWeek = true;

			var diffic = CoolUtil.getDifficultyFilePath(curDifficulty);
			if(diffic == null) diffic = '';

			PlayState.storyDifficulty = curDifficulty;
			PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
			PlayState.campaignScore = 0;
			PlayState.campaignMisses = 0;
			
			CitroTimer.start(1, function() {
				LoadingState.loadAndSwitchState(new PlayState(), true);
				FreeplayState.destroyFreeplayVocals();
			});
		} else {
			SoundPlayer.playSound(Paths.sound('cancelMenu'));
		}
	}

	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty += change;
		if (curDifficulty < 0) curDifficulty = CoolUtil.difficulties.length-1;
		if (curDifficulty >= CoolUtil.difficulties.length) curDifficulty = 0;

		if(loadedWeeks.length > 0) WeekData.setDirectoryFromWeek(loadedWeeks[curWeek]);
		lastDifficultyName = CoolUtil.difficulties[curDifficulty];

		#if !switch
		intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
		#end
	}

	function changeWeek(change:Int = 0):Void
	{
		if(loadedWeeks.length == 0) return;

		curWeek += change;
		if (curWeek >= loadedWeeks.length) curWeek = 0;
		if (curWeek < 0) curWeek = loadedWeeks.length - 1;

		var leWeek:WeekData = loadedWeeks[curWeek];
		WeekData.setDirectoryFromWeek(leWeek);

		txtWeekTitle.text = leWeek.storyName.toUpperCase();
		txtWeekTitle.x = 400 - (txtWeekTitle.CitroG.WIDTH + 10);

		var bullShit:Int = 0;
		var unlocked:Bool = !weekIsLocked(leWeek.fileName);
		
		for (item in grpWeekText) {
			item.targetY = bullShit - curWeek;
			item.alpha = (item.targetY == 0 && unlocked) ? 1 : 0.6;
			bullShit++;
		}

		bgSprite.visible = true;
		var assetName:String = leWeek.weekBackground;
		if(assetName == null || assetName.length < 1) {
			bgSprite.visible = false;
		} else {
			bgSprite.loadGraphic(Paths.image('menubackgrounds/menu_' + assetName));
		}
		PlayState.storyWeek = curWeek;

		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
		var diffStr:String = WeekData.getCurrentWeek().difficulties;
		if(diffStr != null) diffStr = diffStr.trim();

		if(diffStr != null && diffStr.length > 0) {
			var diffs:Array<String> = diffStr.split(',');
			var i:Int = diffs.length - 1;
			while (i > 0) {
				if(diffs[i] != null) {
					diffs[i] = diffs[i].trim();
					if(diffs[i].length < 1) diffs.remove(diffs[i]);
				}
				--i;
			}
			if(diffs.length > 0 && diffs[0].length > 0) {
				CoolUtil.difficulties = diffs;
			}
		}
		
		if(CoolUtil.difficulties.contains(CoolUtil.defaultDifficulty)) {
			curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(CoolUtil.defaultDifficulty)));
		} else {
			curDifficulty = 0;
		}

		var newPos:Int = CoolUtil.difficulties.indexOf(lastDifficultyName);
		if(newPos > -1) curDifficulty = newPos;
		
		updateText();
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!weekCompleted.exists(leWeek.weekBefore) || !weekCompleted.get(leWeek.weekBefore)));
	}

	function updateText():Void
	{
		if(loadedWeeks.length == 0) return;
		var weekArray:Array<String> = loadedWeeks[curWeek].weekCharacters;
		for (i in 0...grpWeekCharacters.length) {
			if(i < weekArray.length) {
				grpWeekCharacters[i].changeCharacter(weekArray[i]);
			}
		}

		var leWeek:WeekData = loadedWeeks[curWeek];
		var stringThing:Array<String> = [];
		for (i in 0...leWeek.songs.length) {
			stringThing.push(leWeek.songs[i][0]);
		}

		txtTracklist.text = '';
		for (i in 0...stringThing.length) {
			txtTracklist.text += stringThing[i] + '\n';
		}
		txtTracklist.text = txtTracklist.text.toUpperCase();
		txtTracklist.screenCenter(X);
		txtTracklist.x -= 400 * 0.35;

		#if !switch
		intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
		#end
	}
}