package options;

class VisualsUISubState extends BaseOptionsMenu {
	public function new() {
		title = 'Visuals and UI';
		rpcTitle = 'Visuals & UI Settings Menu';

		addOption(new Option('Note Splashes', "If unchecked, hitting \"Sick!\" notes won't show particles.", 'noteSplashes', 'bool', true));
		addOption(new Option('Hide HUD', 'If checked, hides most HUD elements.', 'hideHud', 'bool', false));
		addOption(new Option('Time Bar:', "What should the Time Bar display?", 'timeBarType', 'string', 'Time Left', ['Time Left', 'Time Elapsed', 'Song Name', 'Disabled']));
		addOption(new Option('Flashing Lights', "Uncheck this if you're sensitive to flashing lights!", 'flashing', 'bool', true));
		addOption(new Option('Camera Zooms', "If unchecked, the camera won't zoom in on a beat hit.", 'camZooms', 'bool', true));
		addOption(new Option('Score Text Zoom on Hit', "If unchecked, disables the Score text zooming everytime you hit a note.", 'scoreZoom', 'bool', true));
		
		var alphaOpt = new Option('Health Bar Transparency', 'How much transparent should the health bar and icons be.', 'healthBarAlpha', 'percent', 1);
		alphaOpt.scrollSpeed = 1.6;
		alphaOpt.minValue = 0.0;
		alphaOpt.maxValue = 1;
		alphaOpt.changeValue = 0.1;
		alphaOpt.decimals = 1;
		addOption(alphaOpt);
		
		addOption(new Option('FPS Counter', 'If unchecked, hides FPS Counter.', 'showFPS', 'bool', true));
		
		var pauseOpt = new Option('Pause Screen Song:', "What song do you prefer for the Pause Screen?", 'pauseMusic', 'string', 'Tea Time', ['None', 'Breakfast', 'Tea Time']);
		pauseOpt.onChange = onChangePauseMusic;
		addOption(pauseOpt);
		
		addOption(new Option('Check for Updates', 'On Release builds, turn this on to check for updates when you start the game.', 'checkForUpdates', 'bool', true));
		addOption(new Option('Combo Stacking', "If unchecked, Ratings and Combo won't stack, saving on System Memory and making them easier to read", 'comboStacking', 'bool', true));

		super();
	}

	var changedMusic:Bool = false;
	function onChangePauseMusic() {
		changedMusic = true;
	}

	override public function destroy():Void {
		if(changedMusic) {
			MusicPlayer.playSound(Paths.music('freakyMenu'));
		}
		super.destroy();
	}
}