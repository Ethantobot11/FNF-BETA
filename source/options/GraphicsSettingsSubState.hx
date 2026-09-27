package options;

import citro.object.CitroSprite;
import citro.object.CitroText;

class GraphicsSettingsSubState extends BaseOptionsMenu {
	public function new() {
		title = 'Graphics';
		rpcTitle = 'Graphics Settings Menu';

		addOption(new Option('Low Quality', 'If checked, disables some background details, decreases loading times and improves performance.', 'lowQuality', 'bool', false));
		
		var aaOpt = new Option('Anti-Aliasing', 'If unchecked, disables anti-aliasing, increases performance at the cost of sharper visuals.', 'globalAntialiasing', 'bool', true);
		aaOpt.showBoyfriend = true;
		aaOpt.onChange = onChangeAntiAliasing;
		addOption(aaOpt);

		addOption(new Option('Shaders', 'If unchecked, disables shaders. It\'s used for some visual effects, and also CPU intensive for weaker PCs.', 'shaders', 'bool', true));

		// Note: 3DS framerate is hardware-locked to 60 or 30. This option is kept for compatibility but won't change much.
		var fpsOpt = new Option('Framerate', "Pretty self explanatory, isn't it?", 'framerate', 'int', 60);
		fpsOpt.minValue = 30;
		fpsOpt.maxValue = 60;
		fpsOpt.displayFormat = '%v FPS';
		fpsOpt.onChange = onChangeFramerate;
		addOption(fpsOpt);

		super();
	}

	function onChangeAntiAliasing() {
		for (member in this.members) {
			if (Std.isOfType(member, CitroSprite) && !Std.isOfType(member, CitroText)) {
				cast(member, CitroSprite).antialiasing = ClientPrefs.globalAntialiasing;
			}
		}
	}

	function onChangeFramerate() {
		ClientPrefs.framerate = 60; 
	}
}