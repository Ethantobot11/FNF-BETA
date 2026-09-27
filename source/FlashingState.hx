package;

import citro.CitroG;
import citro.state.CitroState;
import citro.object.CitroSprite;
import citro.object.CitroText;
import citro.backend.CitroColor;
import citro.backend.CitroTween;
import citro.backend.CitroTimer;

class FlashingState extends MusicBeatState
{
	public static var leftState:Bool = false;
	var warnText:CitroText;

	override function create():Void
	{
		super.create();

		var bg:CitroSprite = new CitroSprite().makeGraphic(400, 240, CitroColor.BLACK);
		CitroG.state.members.push(bg);

		warnText = new CitroText(0, 0, "Hey, watch out!\nThis Mod contains some flashing lights!\nPress A to disable them now or go to Options Menu.\nPress B to ignore this message.\nYou've been warned!");
		warnText.alignment = CENTER;
		warnText.screenCenter(XY);
		CitroG.state.members.push(warnText);
	}

	override function update(delta:Int):Void
	{
		if(!leftState) {
			if (controls.ACCEPT || controls.BACK) {
				leftState = true;
				if(!controls.BACK) {
					ClientPrefs.flashing = false;
					ClientPrefs.saveSettings();
					SoundPlayer.playSound(Paths.sound('confirmMenu'));
					
					var props = new Map<String, Float>();
					props.set("alpha", 0);
					CitroTween.tweenObject(warnText, props, 1, {
						onComplete: function() {
							CitroTimer.start(0.5, function() {
								MusicBeatState.switchState(new TitleState());
							});
						}
					});
				} else {
					SoundPlayer.playSound(Paths.sound('cancelMenu'));
					var props = new Map<String, Float>();
					props.set("alpha", 0);
					CitroTween.tweenObject(warnText, props, 1, {
						onComplete: function() {
							MusicBeatState.switchState(new TitleState());
						}
					});
				}
			}
		}
		super.update(delta);
	}
}