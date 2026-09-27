package;

import citro.CitroG;
import citro.object.CitroSprite;
import citro.object.CitroText;
import citro.math.CitroMath;
import citro.backend.CitroColor;
import citro.backend.CitroTween;
import haxe3ds.services.HID;
import haxe3ds.services.HID.HIDKey;
import GameplayChangersSubstate;

using StringTools;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];
	var curSelected:Int = 0;
	var curDifficulty:Int = -1;
	var lastDifficultyName:String = '';

	var scoreBG:CitroSprite;
	var scoreText:CitroText;
	var diffText:CitroText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	private var grpSongs:Array<Alphabet> = [];
	private var iconArray:Array<HealthIcon> = [];

	var bg:CitroSprite;
	var intendedColor:CitroColor;
	
	override function create()
	{
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		for (i in 0...WeekData.weeksList.length) {
			if(weekIsLocked(WeekData.weeksList[i])) continue;
			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs) {
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3) colors = [146, 113, 253];
				var col:CitroColor = (0xFF << 24) | (colors[0] << 16) | (colors[1] << 8) | colors[2];
				addSong(song[0], i, song[1], col);
			}
		}
		WeekData.loadTheFirstEnabledMod();

		bg = new CitroSprite();
		bg.loadGraphic(Paths.image('menuDesat'));
		bg.screenCenter();
		CitroG.state.members.push(bg);

		for (i in 0...songs.length) {
			var songText:Alphabet = new Alphabet(90, 320, songs[i].songName, true);
			songText.isMenuItem = true;
			songText.targetY = i - curSelected;
			grpSongs.push(songText);
			CitroG.state.members.push(songText);

			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;
			iconArray.push(icon);
			CitroG.state.members.push(icon);
		}
		WeekData.setDirectoryFromWeek();

		scoreText = new CitroText(CitroG.WIDTH * 0.7, 5, "");
		scoreText.alignment = RIGHT;
		CitroG.state.members.push(scoreText);

		scoreBG = new CitroSprite(scoreText.x - 6, 0).makeGraphic(1, 66, CitroColor.BLACK);
		scoreBG.alpha = 0.6;
		CitroG.state.members.push(scoreBG);

		diffText = new CitroText(scoreText.x, scoreText.y + 36, "");
		CitroG.state.members.push(diffText);

		if(curSelected >= songs.length) curSelected = 0;
		intendedColor = songs[curSelected].color;

		if(lastDifficultyName == '') lastDifficultyName = CoolUtil.defaultDifficulty;
		curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName)));
		
		changeSelection();
		changeDiff();

		var textBG:CitroSprite = new CitroSprite(0, CitroG.HEIGHT - 26).makeGraphic(CitroG.WIDTH, 26, CitroColor.BLACK);
		textBG.alpha = 0.6;
		CitroG.state.members.push(textBG);

		var text:CitroText = new CitroText(textBG.x, textBG.y + 4, "A: Play | B: Back | L: Gameplay Changers | X: Reset Score");
		text.alignment = RIGHT;
		CitroG.state.members.push(text);
		
		super.create();
	}

	override function closeSubState() {
		changeSelection(0, false);
		super.closeSubState();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:CitroColor) {
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	override function update(delta:Int) {
		var elapsed:Float = delta / 1000.0;
		lerpScore = Math.floor(CitroMath.lerp(lerpScore, intendedScore, CitroMath.clamp(elapsed * 24, 0, 1)));
		lerpRating = CitroMath.lerp(lerpRating, intendedRating, CitroMath.clamp(elapsed * 12, 0, 1));

		if (Math.abs(lerpScore - intendedScore) <= 10) lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01) lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(Highscore.floorDecimal(lerpRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) ratingSplit.push('');
		while(ratingSplit[1].length < 2) ratingSplit[1] += '0';

		scoreText.text = 'PERSONAL BEST: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)';
		positionHighscore();

		var upP = controls.UI_UP_P; 
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;
		var back = controls.BACK;
		var reset = controls.RESET;

		if(songs.length > 1) {
			if (upP) changeSelection(-1);
			if (downP) changeSelection(1);
		}

		if (controls.UI_LEFT_P) changeDiff(-1);
		else if (controls.UI_RIGHT_P) changeDiff(1);

		if (back) {
			SoundPlayer.playSound(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}

		// NEW: Open Gameplay Changers with the L button
		if (HID.keyPressed(HIDKey.L)) {
			openSubState(new GameplayChangersSubstate());
		}

		if (accepted) {
			var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
			var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
			
			PlayState.SONG = Song.loadFromJson(poop, songLowercase);
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = curDifficulty;

			LoadingState.loadAndSwitchState(new PlayState());
		}
		else if(reset) {
			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			SoundPlayer.playSound(Paths.sound('scrollMenu'));
		}
		super.update(delta);
	}

	public static function destroyFreeplayVocals():Void {
		SoundPlayer.stopSound(Paths.voices(PlayState.SONG.song));
	}

	function changeDiff(change:Int = 0):Void {
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = CoolUtil.difficulties.length - 1;
		if (curDifficulty >= CoolUtil.difficulties.length)
			curDifficulty = 0;

		lastDifficultyName = CoolUtil.difficulties[curDifficulty];

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		PlayState.storyDifficulty = curDifficulty;
		diffText.text = '< ' + CoolUtil.difficultyString() + ' >';
		positionHighscore();
	}

	function changeSelection(change:Int = 0, playSound:Bool = true) {
		if(playSound) SoundPlayer.playSound(Paths.sound('scrollMenu'));
		curSelected += change;
		if (curSelected < 0) curSelected = songs.length - 1;
		if (curSelected >= songs.length) curSelected = 0;
			
		var newColor:CitroColor = songs[curSelected].color;
		if(newColor != intendedColor) {
			intendedColor = newColor;
			bg.color = intendedColor; 
		}

		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);

		for (i in 0...iconArray.length) iconArray[i].alpha = 0.6;
		iconArray[curSelected].alpha = 1;

		var bullShit:Int = 0;
		for (item in grpSongs) {
			item.targetY = bullShit - curSelected;
			bullShit++;
			item.alpha = 0.6;
			if (item.targetY == 0) item.alpha = 1;
		}
		
		Paths.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;
	}

	private function positionHighscore() {
		scoreText.x = CitroG.WIDTH - scoreText.width - 6;
		scoreBG.scale.x = CitroG.WIDTH - scoreText.x + 6;
		scoreBG.x = CitroG.WIDTH - (scoreBG.scale.x / 2);
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
	}
}

class SongMetadata {
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:CitroColor = 0xFF9271FD;
	public var folder:String = "";

	public function new(song:String, week:Int, songCharacter:String, color:CitroColor) {
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Paths.currentModDirectory;
		if(this.folder == null) this.folder = '';
	}
}