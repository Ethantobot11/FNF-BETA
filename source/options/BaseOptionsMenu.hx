package options;

import citro.CitroG;
import citro.state.CitroSubState;
import citro.object.CitroSprite;
import citro.object.CitroText;
import citro.backend.CitroColor;
import citro.math.CitroMath;

using StringTools;

class BaseOptionsMenu extends MusicBeatSubstate
{
	private var curOption:Option = null;
	private var curSelected:Int = 0;
	private var optionsArray:Array<Option>;

	private var grpOptions:Array<Alphabet> = [];
	private var checkboxGroup:Array<CheckboxThingie> = [];
	private var grpTexts:Array<CitroText> = [];

	private var boyfriend:Character = null;
	private var descBox:CitroSprite;
	private var descText:CitroText;

	public var title:String;
	public var rpcTitle:String;

	public function new() {
		super();

		if(title == null) title = 'Options';
		if(rpcTitle == null) rpcTitle = 'Options Menu';
		
		var bg:CitroSprite = new CitroSprite();
		bg.loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		bg.screenCenter();
		this.members.push(bg);

		descBox = new CitroSprite().makeGraphic(1, 1, CitroColor.BLACK);
		descBox.alpha = 0.6;
		this.members.push(descBox);

		var titleText:Alphabet = new Alphabet(75, 40, title, true);
		titleText.scale.set(0.6, 0.6);
		titleText.alpha = 0.4;
		this.members.push(titleText);

		descText = new CitroText(50, 600, "");
		descText.alignment = CENTER;
		this.members.push(descText);

		for (i in 0...optionsArray.length) {
			var optionText:Alphabet = new Alphabet(290, 260, optionsArray[i].name, false);
			optionText.isMenuItem = true;
			optionText.targetY = i;
			grpOptions.push(optionText);
			this.members.push(optionText);

			if(optionsArray[i].type == 'bool') {
				var checkbox:CheckboxThingie = new CheckboxThingie(optionText.x - 105, optionText.y, optionsArray[i].getValue() == true);
				checkbox.sprTracker = optionText;
				checkboxGroup.push(checkbox);
				this.members.push(checkbox);
			} else {
				optionText.x -= 80;
				optionText.startPosition.x -= 80;
				var valueText:CitroText = new CitroText(optionText.x + optionText.width + 80, optionText.y, '' + optionsArray[i].getValue());
				valueText.alignment = LEFT;
				grpTexts.push(valueText);
				this.members.push(valueText);
				optionsArray[i].setChild(valueText);
			}

			if(optionsArray[i].showBoyfriend && boyfriend == null) {
				reloadBoyfriend();
			}
			updateTextFrom(optionsArray[i]);
		}

		changeSelection();
		reloadCheckboxes();
	}

	public function addOption(option:Option) {
		if(optionsArray == null) optionsArray = [];
		optionsArray.push(option);
	}

	var nextAccept:Int = 5;
	var holdTime:Float = 0;
	var holdValue:Float = 0;

	override public function update(delta:Int):Void {
		var elapsed:Float = delta / 1000.0;

		if (controls.UI_UP_P) changeSelection(-1);
		if (controls.UI_DOWN_P) changeSelection(1);

		if (controls.BACK) {
			closeSub();
			SoundPlayer.playSound(Paths.sound('cancelMenu'));
		}

		if(nextAccept <= 0) {
			var usesCheckbox = (curOption.type == 'bool');

			if(usesCheckbox) {
				if(controls.ACCEPT) {
					SoundPlayer.playSound(Paths.sound('scrollMenu'));
					curOption.setValue(!(curOption.getValue() == true));
					curOption.change();
					reloadCheckboxes();
				}
			} else {
				if(controls.UI_LEFT || controls.UI_RIGHT) {
					var pressed = (controls.UI_LEFT_P || controls.UI_RIGHT_P);
					if(holdTime > 0.5 || pressed) {
						if(pressed) {
							var add:Dynamic = null;
							if(curOption.type != 'string') {
								add = controls.UI_LEFT ? -curOption.changeValue : curOption.changeValue;
							}

							switch(curOption.type) {
								case 'int', 'float', 'percent':
									holdValue = curOption.getValue() + add;
									if(holdValue < curOption.minValue) holdValue = curOption.minValue;
									else if (holdValue > curOption.maxValue) holdValue = curOption.maxValue;

									switch(curOption.type) {
										case 'int':
											holdValue = Math.round(holdValue);
											curOption.setValue(holdValue);
										case 'float', 'percent':
											holdValue = CitroMath.roundDecimal(holdValue, curOption.decimals);
											curOption.setValue(holdValue);
									}
								case 'string':
									var num:Int = curOption.curOption;
									if(controls.UI_LEFT_P) --num;
									else num++;

									if(num < 0) num = curOption.options.length - 1;
									else if(num >= curOption.options.length) num = 0;

									curOption.curOption = num;
									curOption.setValue(curOption.options[num]);
							}
							updateTextFrom(curOption);
							curOption.change();
							SoundPlayer.playSound(Paths.sound('scrollMenu'));
						} else if(curOption.type != 'string') {
							holdValue += curOption.scrollSpeed * elapsed * (controls.UI_LEFT ? -1 : 1);
							if(holdValue < curOption.minValue) holdValue = curOption.minValue;
							else if (holdValue > curOption.maxValue) holdValue = curOption.maxValue;

							switch(curOption.type) {
								case 'int':
									curOption.setValue(Math.round(holdValue));
								case 'float', 'percent':
									curOption.setValue(CitroMath.roundDecimal(holdValue, curOption.decimals));
							}
							updateTextFrom(curOption);
							curOption.change();
						}
					}
					if(curOption.type != 'string') holdTime += elapsed;
				} else if(controls.UI_LEFT_R || controls.UI_RIGHT_R) {
					clearHold();
				}
			}

			if(controls.RESET) {
				for (i in 0...optionsArray.length) {
					var leOption:Option = optionsArray[i];
					leOption.setValue(leOption.defaultValue);
					if(leOption.type != 'bool') {
						if(leOption.type == 'string' && leOption.options != null) {
							leOption.curOption = leOption.options.indexOf(leOption.getValue());
						}
						updateTextFrom(leOption);
					}
					leOption.change();
				}
				SoundPlayer.playSound(Paths.sound('cancelMenu'));
				reloadCheckboxes();
			}
		}

		if(boyfriend != null && boyfriend.curAnim != null && boyfriend.finished) {
			boyfriend.dance();
		}

		if(nextAccept > 0) nextAccept -= 1;
		super.update(delta);
	}

	function updateTextFrom(option:Option) {
		var text:String = option.displayFormat;
		var val:Dynamic = option.getValue();
		if(option.type == 'percent') val *= 100;
		var def:Dynamic = option.defaultValue;
		option.text = text.replace('%v', val).replace('%d', def);
	}

	function clearHold() {
		if(holdTime > 0.5) SoundPlayer.playSound(Paths.sound('scrollMenu'));
		holdTime = 0;
	}
	
	function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0) curSelected = optionsArray.length - 1;
		if (curSelected >= optionsArray.length) curSelected = 0;

		descText.text = optionsArray[curSelected].description;
		descText.screenCenter(X);
		descText.y += 270;

		var bullShit:Int = 0;
		for (item in grpOptions) {
			item.targetY = bullShit - curSelected;
			bullShit++;
			item.alpha = (item.targetY == 0) ? 1 : 0.6;
		}
		for (text in grpTexts) {
			text.alpha = (text.x == grpOptions[curSelected].x + grpOptions[curSelected].width + 80) ? 1 : 0.6;
		}

		descBox.x = descText.x - 10;
		descBox.y = descText.y - 10;
		descBox.setSourceRect(0, 0, Std.int(descText.width + 20), Std.int(descText.height + 25));

		if(boyfriend != null) {
			boyfriend.visible = optionsArray[curSelected].showBoyfriend;
		}
		curOption = optionsArray[curSelected];
		SoundPlayer.playSound(Paths.sound('scrollMenu'));
	}

	public function reloadBoyfriend() {
		var wasVisible:Bool = false;
		if(boyfriend != null) {
			wasVisible = boyfriend.visible;
			this.members.remove(boyfriend);
			boyfriend.destroy();
		}

		boyfriend = new Character(840, 170, 'bf', true);
		boyfriend.scale.set(0.75, 0.75);
		boyfriend.dance();
		this.members.push(boyfriend);
		boyfriend.visible = wasVisible;
	}

	function reloadCheckboxes() {
		for (checkbox in checkboxGroup) {
			checkbox.daValue = (optionsArray[checkboxGroup.indexOf(checkbox)].getValue() == true);
		}
	}
}