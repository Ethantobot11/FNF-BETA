package options;

import citro.CitroG;
import citro.object.CitroSprite;
import citro.backend.CitroColor;

using StringTools;

class OptionsState extends MusicBeatState {
	var options:Array<String> = ['Note Colors', 'Controls', 'Adjust Delay and Combo', 'Graphics', 'Visuals and UI', 'Gameplay'];
	private var grpOptions:Array<Alphabet> = [];
	private static var curSelected:Int = 0;
	public static var menuBG:CitroSprite;

	function openSelectedSubstate(label:String) {
		switch(label) {
			case 'Note Colors': openSubState(new options.NotesSubState());
			case 'Controls': openSubState(new options.ControlsSubState());
			case 'Graphics': openSubState(new options.GraphicsSettingsSubState());
			case 'Visuals and UI': openSubState(new options.VisualsUISubState());
			case 'Gameplay': openSubState(new options.GameplaySettingsSubState());
			case 'Adjust Delay and Combo': LoadingState.loadAndSwitchState(new options.NoteOffsetState());
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	override public function create():Void {
		var bg:CitroSprite = new CitroSprite();
		bg.loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		bg.screenCenter();
		CitroG.state.members.push(bg);

		for (i in 0...options.length) {
			var optionText:Alphabet = new Alphabet(0, 0, options[i], true);
			optionText.screenCenter(X);
			optionText.y += (100 * (i - (options.length / 2))) + 50;
			grpOptions.push(optionText);
			CitroG.state.members.push(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true);
		CitroG.state.members.push(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true);
		CitroG.state.members.push(selectorRight);

		changeSelection();
		ClientPrefs.saveSettings();
		super.create();
	}

	override public function closeSubState():Void {
		super.closeSubState();
		ClientPrefs.saveSettings();
	}

	override public function update(delta:Int):Void {
		var elapsed:Float = delta / 1000.0;
		super.update(delta);

		if (controls.UI_UP_P) changeSelection(-1);
		if (controls.UI_DOWN_P) changeSelection(1);

		if (controls.BACK) {
			SoundPlayer.playSound(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}

		if (controls.ACCEPT) {
			openSelectedSubstate(options[curSelected]);
		}
	}
	
	function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0) curSelected = options.length - 1;
		if (curSelected >= options.length) curSelected = 0;

		var bullShit:Int = 0;
		for (item in grpOptions) {
			item.targetY = bullShit - curSelected;
			bullShit++;
			item.alpha = (item.targetY == 0) ? 1 : 0.6;
			
			if (item.targetY == 0) {
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}
		SoundPlayer.playSound(Paths.sound('scrollMenu'));
	}
}