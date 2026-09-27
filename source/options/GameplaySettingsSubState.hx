package options;

class GameplaySettingsSubState extends BaseOptionsMenu {
	public function new() {
		title = 'Gameplay Settings';
		rpcTitle = 'Gameplay Settings Menu';

		addOption(new Option('Controller Mode', 'Check this if you want to play with a controller instead of using your Keyboard.', 'controllerMode', 'bool', false));
		addOption(new Option('Downscroll', 'If checked, notes go Down instead of Up, simple enough.', 'downScroll', 'bool', false));
		addOption(new Option('Middlescroll', 'If checked, your notes get centered.', 'middleScroll', 'bool', false));
		addOption(new Option('Opponent Notes', 'If unchecked, opponent notes get hidden.', 'opponentStrums', 'bool', true));
		addOption(new Option('Ghost Tapping', "If checked, you won't get misses from pressing keys while there are no notes able to be hit.", 'ghostTapping', 'bool', true));
		addOption(new Option('Disable Reset Button', "If checked, pressing Reset won't do anything.", 'noReset', 'bool', false));
		
		var hitsoundOpt = new Option('Hitsound Volume', 'Funny notes does "Tick!" when you hit them."', 'hitsoundVolume', 'percent', 0);
		hitsoundOpt.scrollSpeed = 1.6;
		hitsoundOpt.minValue = 0.0;
		hitsoundOpt.maxValue = 1;
		hitsoundOpt.changeValue = 0.1;
		hitsoundOpt.decimals = 1;
		hitsoundOpt.onChange = onChangeHitsoundVolume;
		addOption(hitsoundOpt);

		var ratingOpt = new Option('Rating Offset', 'Changes how late/early you have to hit for a "Sick!"\nHigher values mean you have to hit later.', 'ratingOffset', 'int', 0);
		ratingOpt.displayFormat = '%vms';
		ratingOpt.scrollSpeed = 20;
		ratingOpt.minValue = -30;
		ratingOpt.maxValue = 30;
		addOption(ratingOpt);

		addOption(new Option('Sick! Hit Window', 'Changes the amount of time you have for hitting a "Sick!" in milliseconds.', 'sickWindow', 'int', 45));
		addOption(new Option('Good Hit Window', 'Changes the amount of time you have for hitting a "Good" in milliseconds.', 'goodWindow', 'int', 90));
		addOption(new Option('Bad Hit Window', 'Changes the amount of time you have for hitting a "Bad" in milliseconds.', 'badWindow', 'int', 135));

		var safeOpt = new Option('Safe Frames', 'Changes how many frames you have for hitting a note earlier or late.', 'safeFrames', 'float', 10);
		safeOpt.scrollSpeed = 5;
		safeOpt.minValue = 2;
		safeOpt.maxValue = 10;
		safeOpt.changeValue = 0.1;
		addOption(safeOpt);

		super();
	}

	function onChangeHitsoundVolume() {
		SoundPlayer.playSound(Paths.sound('hitsound'));
	}
}