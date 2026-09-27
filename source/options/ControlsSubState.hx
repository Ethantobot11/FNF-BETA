package options;

import citro.CitroG;
import citro.object.CitroSprite;
import citro.object.CitroText;
import citro.backend.CitroColor;

using StringTools;

class ControlsSubState extends MusicBeatSubstate {
	private static var curSelected:Int = 1;
	private static var curAlt:Bool = false;

	private static var defaultKey:String = 'Reset to Default Keys';
	private var bindLength:Int = 0;

	var optionShit:Array<Dynamic> = [
		['NOTES'],
		['Left', 'note_left'],
		['Down', 'note_down'],
		['Up', 'note_up'],
		['Right', 'note_right'],
		[''],
		['UI'],
		['Left', 'ui_left'],
		['Down', 'ui_down'],
		['Up', 'ui_up'],
		['Right', 'ui_right'],
		[''],
		['Reset', 'reset'],
		['Accept', 'accept'],
		['Back', 'back'],
		['Pause', 'pause'],
		[''],
		['VOLUME'],
		['Mute', 'volume_mute'],
		['Up', 'volume_up'],
		['Down', 'volume_down'],
		[''],
		['DEBUG'],
		['Key 1', 'debug_1'],
		['Key 2', 'debug_2']
	];

	private var grpOptions:Array<Alphabet> = [];
	private var grpInputs:Array<CitroText> = [];
	private var grpInputsAlt:Array<CitroText> = [];
	var rebindingKey:Bool = false;
	var nextAccept:Int = 5;

	public function new() {
		super();

		var bg:CitroSprite = new CitroSprite();
		bg.loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		bg.screenCenter();
		this.members.push(bg);

		for (i in 0...optionShit.length) {
			var isCentered:Bool = false;
			var isDefaultKey:Bool = (optionShit[i][0] == defaultKey);
			if(unselectableCheck(i, true)) isCentered = true;

			var optionText:Alphabet = new Alphabet(200, 300, optionShit[i][0], (!isCentered || isDefaultKey));
			optionText.isMenuItem = true;
			if(isCentered) {
				optionText.x = (CitroG.WIDTH - optionText.width) / 2;
				optionText.y -= 55;
				optionText.startPosition.y -= 55;
			}
			optionText.changeX = false;
			optionText.distancePerItemY = 60;
			optionText.targetY = i - curSelected;
			optionText.snapToPosition();
			grpOptions.push(optionText);
			this.members.push(optionText);

			if(!isCentered) {
				addBindTexts(optionText, i);
				bindLength++;
				if(curSelected < 0) curSelected = i;
			}
		}
		changeSelection();
	}

	var leaving:Bool = false;
	var bindingTime:Float = 0;

	override public function update(delta:Int):Void {
		var elapsed:Float = delta / 1000.0;

		if(!rebindingKey) {
			if (controls.UI_UP_P) changeSelection(-1);
			if (controls.UI_DOWN_P) changeSelection(1);
			if (controls.UI_LEFT_P || controls.UI_RIGHT_P) changeAlt();

			if (controls.BACK) {
				ClientPrefs.reloadControls();
				closeSub();
				SoundPlayer.playSound(Paths.sound('cancelMenu'));
			}

			if(controls.ACCEPT && nextAccept <= 0) {
				if(optionShit[curSelected][0] == defaultKey) {
					ClientPrefs.keyBinds = ClientPrefs.defaultKeys.copy();
					reloadKeys();
					changeSelection();
					SoundPlayer.playSound(Paths.sound('confirmMenu'));
				} else if(!unselectableCheck(curSelected)) {
					bindingTime = 0;
					rebindingKey = true;
					if (curAlt) {
						grpInputsAlt[getInputTextNum()].alpha = 0;
					} else {
						grpInputs[getInputTextNum()].alpha = 0;
					}
					SoundPlayer.playSound(Paths.sound('scrollMenu'));
				}
			}
		} else {
			// TODO: 3DS Key rebinding is not natively supported as buttons are fixed. 
			// This section is kept for PC/Emulator compatibility if you add custom HID polling.
			bindingTime += elapsed;
			if(bindingTime > 5) {
				if (curAlt) grpInputsAlt[curSelected].alpha = 1;
				else grpInputs[curSelected].alpha = 1;
				SoundPlayer.playSound(Paths.sound('scrollMenu'));
				rebindingKey = false;
				bindingTime = 0;
			}
		}

		if(nextAccept > 0) nextAccept -= 1;
		super.update(delta);
	}

	function getInputTextNum():Int {
		var num:Int = 0;
		for (i in 0...curSelected) {
			if(optionShit[i].length > 1) num++;
		}
		return num;
	}
	
	function changeSelection(change:Int = 0) {
		do {
			curSelected += change;
			if (curSelected < 0) curSelected = optionShit.length - 1;
			if (curSelected >= optionShit.length) curSelected = 0;
		} while(unselectableCheck(curSelected));

		var bullShit:Int = 0;
		for (i in 0...grpInputs.length) grpInputs[i].alpha = 0.6;
		for (i in 0...grpInputsAlt.length) grpInputsAlt[i].alpha = 0.6;

		for (item in grpOptions) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			if(!unselectableCheck(bullShit-1)) {
				item.alpha = 0.6;
				if (item.targetY == 0) {
					item.alpha = 1;
					if(curAlt) {
						for (i in 0...grpInputsAlt.length) {
							if(grpInputsAlt[i].x == item.x + 650) { grpInputsAlt[i].alpha = 1; break; }
						}
					} else {
						for (i in 0...grpInputs.length) {
							if(grpInputs[i].x == item.x + 400) { grpInputs[i].alpha = 1; break; }
						}
					}
				}
			}
		}
		SoundPlayer.playSound(Paths.sound('scrollMenu'));
	}

	function changeAlt() {
		curAlt = !curAlt;
		for (i in 0...grpInputs.length) {
			if(grpInputs[i].x == grpOptions[curSelected].x + 400) {
				grpInputs[i].alpha = curAlt ? 0.6 : 1;
				break;
			}
		}
		for (i in 0...grpInputsAlt.length) {
			if(grpInputsAlt[i].x == grpOptions[curSelected].x + 650) {
				grpInputsAlt[i].alpha = curAlt ? 1 : 0.6;
				break;
			}
		}
		SoundPlayer.playSound(Paths.sound('scrollMenu'));
	}

	private function unselectableCheck(num:Int, ?checkDefaultKey:Bool = false):Bool {
		if(optionShit[num][0] == defaultKey) return checkDefaultKey;
		return optionShit[num].length < 2 && optionShit[num][0] != defaultKey;
	}

	private function addBindTexts(optionText:Alphabet, num:Int) {
		var keys:Array<Dynamic> = ClientPrefs.keyBinds.get(optionShit[num][1]);
		var text1 = new CitroText(optionText.x + 400, optionText.y - 55, InputFormatter.getKeyName(keys[0]));
		text1.alignment = LEFT;
		grpInputs.push(text1);
		this.members.push(text1);

		var text2 = new CitroText(optionText.x + 650, optionText.y - 55, InputFormatter.getKeyName(keys[1]));
		text2.alignment = LEFT;
		grpInputsAlt.push(text2);
		this.members.push(text2);
	}

	function reloadKeys() {
		for (item in grpInputs) { this.members.remove(item); item.destroy(); }
		grpInputs = [];
		for (item in grpInputsAlt) { this.members.remove(item); item.destroy(); }
		grpInputsAlt = [];

		for (i in 0...grpOptions.length) {
			if(!unselectableCheck(i, true)) addBindTexts(grpOptions[i], i);
		}
		changeSelection(0);
	}
}