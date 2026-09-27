package;

import citro.CitroG;
import citro.state.CitroSubState;
import citro.object.CitroSprite;
import citro.backend.CitroColor;
import Controls;
import PlayerSettings;

using StringTools;
@:headerInclude("3ds.h")
class ResetScoreSubState extends CitroSubState
{
	var controls(get, never):Controls;
	inline function get_controls():Controls return PlayerSettings.player1.controls;

	var bg:CitroSprite;
	var alphabetArray:Array<Alphabet> = [];
	var icon:HealthIcon;
	var onYes:Bool = false;
	var yesText:Alphabet;
	var noText:Alphabet;

	var song:String;
	var difficulty:Int;
	var week:Int;

	public function new(song:String, difficulty:Int, character:String, week:Int = -1)
	{
		super();
		this.song = song;
		this.difficulty = difficulty;
		this.week = week;

		var name:String = song;
		if(week > -1) {
			name = WeekData.weeksLoaded.get(WeekData.weeksList[week]).weekName;
		}
		name += ' (' + CoolUtil.difficulties[difficulty] + ')?';

		bg = new CitroSprite().makeGraphic(CitroG.WIDTH, CitroG.HEIGHT, CitroColor.BLACK);
		bg.alpha = 0;
		this.members.push(bg);

		var tooLong:Float = (name.length > 18) ? 0.8 : 1;
		
		var text1:Alphabet = new Alphabet(0, 180, "Reset the score of", true);
		text1.x = (CitroG.WIDTH - text1.width) / 2;
		alphabetArray.push(text1);
		text1.alpha = 0;
		this.members.push(text1);
		
		var text2:Alphabet = new Alphabet(0, text1.y + 90, name, true);
		text2.scale.set(tooLong, tooLong);
		text2.x = (CitroG.WIDTH - text2.width) / 2;
		if(week == -1) text2.x += 60 * tooLong;
		alphabetArray.push(text2);
		text2.alpha = 0;
		this.members.push(text2);
		
		if(week == -1) {
			icon = new HealthIcon(character);
			icon.scale.set(tooLong, tooLong);
			
			icon.x = text2.x - icon.width + (10 * tooLong);
			icon.y = text2.y - 30;
			
			icon.alpha = 0;
			this.members.push(icon);
		}

		yesText = new Alphabet(0, text2.y + 150, 'Yes', true);
		yesText.x = ((CitroG.WIDTH - yesText.width) / 2) - 200;
		this.members.push(yesText);
		
		noText = new Alphabet(0, text2.y + 150, 'No', true);
		noText.x = ((CitroG.WIDTH - noText.width) / 2) + 200;
		this.members.push(noText);
		
		updateOptions();
	}

	override public function update(delta:Int):Void
	{
		var elapsed:Float = delta / 1000.0;
		
		bg.alpha += elapsed * 1.5;
		if(bg.alpha > 0.6) bg.alpha = 0.6;

		for (i in 0...alphabetArray.length) {
			var spr = alphabetArray[i];
			spr.alpha += elapsed * 2.5;
		}
		if(week == -1 && icon != null) icon.alpha += elapsed * 2.5;

		if(controls.UI_LEFT_P || controls.UI_RIGHT_P) {
			SoundPlayer.playSound(Paths.sound('scrollMenu'));
			onYes = !onYes;
			updateOptions();
		}
		if(controls.BACK) {
			SoundPlayer.playSound(Paths.sound('cancelMenu'));
			closeSub();
		} else if(controls.ACCEPT) {
			if(onYes) {
				if(week == -1) {
					Highscore.resetSong(song, difficulty);
				} else {
					Highscore.resetWeek(WeekData.weeksList[week], difficulty);
				}
			}
			SoundPlayer.playSound(Paths.sound('cancelMenu'));
			closeSub();
		}
		super.update(delta);
	}

	function closeSub():Void {
		CitroG.substate = null;
	}

	function updateOptions():Void {
		var scales:Array<Float> = [0.75, 1];
		var alphas:Array<Float> = [0.6, 1.25];
		var confirmInt:Int = onYes ? 1 : 0;

		yesText.alpha = alphas[confirmInt];
		yesText.scale.set(scales[confirmInt], scales[confirmInt]);
		noText.alpha = alphas[1 - confirmInt];
		noText.scale.set(scales[1 - confirmInt], scales[1 - confirmInt]);
		
		if(week == -1 && icon != null) {
			icon.setLosing(confirmInt == 1);
		}
	}
}