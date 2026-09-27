package;

import citro.CitroG;
import citro.object.CitroSprite;
import citro.object.CitroText;
import citro.backend.CitroColor;
import citro.math.CitroMath;

using StringTools;

class GameplayChangersSubstate extends MusicBeatSubstate
{
	private var curOption:GameplayOption = null;
	private var curSelected:Int = 0;
	private var optionsArray:Array<GameplayOption> = [];

	private var grpOptions:Array<Alphabet> = [];
	private var checkboxGroup:Array<CheckboxThingie> = [];
	private var grpTexts:Array<CitroText> = [];

	public function new() {
		super();
		var bg:CitroSprite = new CitroSprite().makeGraphic(CitroG.WIDTH, CitroG.HEIGHT, CitroColor.BLACK);
		bg.alpha = 0.6;
		CitroG.state.members.push(bg);

		getOptions();
		for (i in 0...optionsArray.length) {
			var optionText:Alphabet = new Alphabet(200, 360, optionsArray[i].name, true);
			optionText.isMenuItem = true;
			optionText.scale.set(0.8, 0.8);
			optionText.targetY = i;
			grpOptions.push(optionText);
			CitroG.state.members.push(optionText);

			if(optionsArray[i].type == 'bool') {
				optionText.x += 110;
				optionText.startPosition.x += 110;
				optionText.snapToPosition();
				var checkbox:CheckboxThingie = new CheckboxThingie(optionText.x - 105, optionText.y, optionsArray[i].getValue() == true);
				checkbox.sprTracker = optionText;
				checkbox.offsetX -= 32;
				checkbox.offsetY = -120;
				checkboxGroup.push(checkbox);
				CitroG.state.members.push(checkbox);
			} else {
				optionText.snapToPosition();
				var valueText:CitroText = new CitroText(optionText.x + optionText.width, optionText.y - 72, Std.string(optionsArray[i].getValue()));
				valueText.alignment = LEFT;
				valueText.scale.set(0.8, 0.8);
				grpTexts.push(valueText);
				CitroG.state.members.push(valueText);
				optionsArray[i].setChild(valueText);
		 }
			updateTextFrom(optionsArray[i]);
		}
		changeSelection();
		reloadCheckboxes();
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
			ClientPrefs.saveSettings();
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
							var add:Dynamic = (curOption.type != 'string') ? (controls.UI_LEFT ? -curOption.changeValue : curOption.changeValue) : null;
							switch(curOption.type) {
								case 'int' | 'float' | 'percent':
									holdValue = curOption.getValue() + add;
									holdValue = Math.max(curOption.minValue, Math.min(curOption.maxValue, holdValue));
									curOption.setValue(curOption.type == 'int' ? Math.round(holdValue) : CitroMath.roundDecimal(holdValue, curOption.decimals));
								case 'string':
									var num:Int = curOption.curOption;
									if(controls.UI_LEFT_P) --num; else num++;
									if(num < 0) num = curOption.options.length - 1;
									else if(num >= curOption.options.length) num = 0;
									curOption.curOption = num;
									curOption.setValue(curOption.options[num]);
							}
							updateTextFrom(curOption);
							curOption.change();
							SoundPlayer.playSound(Paths.sound('scrollMenu'));
						} else if(curOption.type != 'string') {
							holdValue = Math.max(curOption.minValue, Math.min(curOption.maxValue, holdValue + curOption.scrollSpeed * elapsed * (controls.UI_LEFT ? -1 : 1)));
							curOption.setValue(curOption.type == 'int' ? Math.round(holdValue) : CitroMath.roundDecimal(holdValue, curOption.decimals));
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
					var leOption:GameplayOption = optionsArray[i];
					leOption.setValue(leOption.defaultValue);
					if(leOption.type == 'string') leOption.curOption = leOption.options.indexOf(leOption.getValue());
					updateTextFrom(leOption);
					leOption.change();
				}
				SoundPlayer.playSound(Paths.sound('cancelMenu'));
				reloadCheckboxes();
			}
		}
		if(nextAccept > 0) nextAccept -= 1;
		super.update(delta);
	}

	override function closeSub():Void { CitroG.substate = null; }

	function updateTextFrom(option:GameplayOption) {
		var text:String = option.displayFormat;
		var val:Dynamic = option.type == 'percent' ? option.getValue() * 100 : option.getValue();
		option.text = text.replace('%v', val).replace('%d', option.defaultValue);
	}

	function clearHold() {
		if(holdTime > 0.5) SoundPlayer.playSound(Paths.sound('scrollMenu'));
		holdTime = 0;
	}
	
	function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0) curSelected = optionsArray.length - 1;
		if (curSelected >= optionsArray.length) curSelected = 0;

		var bullShit:Int = 0;
		for (item in grpOptions) {
			item.targetY = bullShit - curSelected;
			bullShit++;
			item.alpha = (item.targetY == 0) ? 1 : 0.6;
	 }
		for (text in grpTexts) {
			text.alpha = (text.x == grpOptions[curSelected].x + grpOptions[curSelected].width) ? 1 : 0.6; // Simplified ID check
		}
		curOption = optionsArray[curSelected];
		SoundPlayer.playSound(Paths.sound('scrollMenu'));
	}

	function reloadCheckboxes() {
		for (checkbox in checkboxGroup) {
			checkbox.daValue = (optionsArray[checkboxGroup.indexOf(checkbox)].getValue() == true);
		}
	}

	function getOptions() {
		optionsArray.push(new GameplayOption('Scroll Type', 'scrolltype', 'string', 'multiplicative', ["multiplicative", "constant"]));
		var opt1 = new GameplayOption('Scroll Speed', 'scrollspeed', 'float', 1);
		opt1.scrollSpeed = 2.0; opt1.minValue = 0.35; opt1.changeValue = 0.05; opt1.decimals = 2; opt1.maxValue = 3;
		optionsArray.push(opt1);
		optionsArray.push(new GameplayOption('Health Gain Multiplier', 'healthgain', 'float', 1));
		optionsArray.push(new GameplayOption('Health Loss Multiplier', 'healthloss', 'float', 1));
		optionsArray.push(new GameplayOption('Instakill on Miss', 'instakill', 'bool', false));
		optionsArray.push(new GameplayOption('Practice Mode', 'practice', 'bool', false));
		optionsArray.push(new GameplayOption('Botplay', 'botplay', 'bool', false));
	}
}

class GameplayOption {
	private var child:CitroText;
	public var text(get, set):String;
	public var onChange:Void->Void = null;
	public var type(get, default):String = 'bool';
	public var showBoyfriend:Bool = false;
	public var scrollSpeed:Float = 50;
	private var variable:String = null;
	public var defaultValue:Dynamic = null;
	public var curOption:Int = 0;
	public var options:Array<String> = null;
	public var changeValue:Dynamic = 1;
	public var minValue:Dynamic = null;
	public var maxValue:Dynamic = null;
	public var decimals:Int = 1;
	public var displayFormat:String = '%v';
	public var name:String = 'Unknown';

	public function new(name:String, variable:String, type:String = 'bool', defaultValue:Dynamic = null, ?options:Array<String> = null) {
		this.name = name; this.variable = variable; this.type = type; this.defaultValue = defaultValue; this.options = options;
		if(getValue() == null) setValue(defaultValue);
		if(type == 'string') { var num = options.indexOf(getValue()); if(num > -1) curOption = num; }
	}
	public function change() { if(onChange != null) onChange(); }
	public function getValue():Dynamic return ClientPrefs.gameplaySettings.get(variable);
	public function setValue(value:Dynamic) ClientPrefs.gameplaySettings.set(variable, value);
	public function setChild(child:CitroText) this.child = child;
	private function get_text() return child != null ? child.text : null;
	private function set_text(newValue:String) { if(child != null) child.text = newValue; return newValue; }
	private function get_type() {
		var newValue = 'bool';
		switch(type.toLowerCase().trim()) {
			case 'int', 'float', 'percent', 'string': newValue = type;
			case 'integer': newValue = 'int'; case 'str': newValue = 'string'; case 'fl': newValue = 'float';
		}
		return newValue;
	}
}