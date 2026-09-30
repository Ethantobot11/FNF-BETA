package;

import citro.CitroG;
import citro.state.CitroState;
import citro.object.CitroSprite;
import citro.object.CitroText;
import citro.backend.CitroColor;
import citro.backend.CitroTween;
import citro.backend.CitroTimer;
import haxe3ds.services.HID;
import haxe3ds.services.HID.HIDKey;

@:headerInclude("3ds.h")
class FlashingState extends MusicBeatState
{
	public static var leftState:Bool = false;
	var warnText:CitroText;
	var gjHintText:CitroText;

	override function create():Void
	{
		super.create();

		var bg:CitroSprite = new CitroSprite().makeGraphic(400, 240, CitroColor.BLACK);
		CitroG.state.members.push(bg);

		warnText = new CitroText(0, 0, "WARNING!\nFlashing lights ahead!\n\nPress A to disable\nPress B to ignore", true);
		warnText.alignment = CENTER;
		warnText.screenCenter(XY);
		warnText.y -= 20;
		CitroG.state.members.push(warnText);

		gjHintText = new CitroText(0, 210, "Press [L] for GameJolt Login", false);
		gjHintText.alignment = CENTER;
		gjHintText.screenCenter(X);
		gjHintText.color = CitroColor.GRAY;
		CitroG.state.members.push(gjHintText);
	}

	override function update(delta:Int):Void
	{
		if(!leftState) {
			if (HID.keyPressed(HIDKey.L)) {
				MusicBeatState.switchState(new GameJoltLoginState());
				return;
			}

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
								MusicBeatState.switchState(new options.OptionsState());
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