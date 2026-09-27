package;

import citro.object.CitroAnimate;
import citro.object.CitroObject;
import citro.CitroG;

using StringTools;

class HealthIcon extends CitroAnimate
{
	public var sprTracker:CitroObject = null; // Can be any CitroObject
	private var isOldIcon:Bool = false;
	private var isPlayer:Bool = false;
	private var char:String = '';

	private var iconOffsets:Array<Float> = [0, 0];

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super(0, 0, ""); // Dummy path, changed in changeIcon
		this.isOldIcon = (char == 'bf-old');
		this.isPlayer = isPlayer;
		changeIcon(char);
	}

	override public function update(delta:Int):Bool
	{
		if (sprTracker != null) {
			// Adjust position relative to the tracked object (e.g., HealthBar)
			this.x = sprTracker.x + sprTracker.width + 12;
			this.y = sprTracker.y - 30;
		}
		return super.update(delta);
	}

	public function swapOldIcon():Void 
	{
		isOldIcon = !isOldIcon;
		if(isOldIcon) {
			changeIcon('bf-old');
		} else {
			changeIcon('bf');
		}
	}

	public function changeIcon(newChar:String):Void 
	{
		if(this.char != newChar) {
			var name:String = 'icons/' + newChar;
			
			// Fallback logic for missing icons
			if(!Paths.getPreloadPath('images/' + name + '.cea', "TEXT")) {
				name = 'icons/icon-' + newChar;
			}
			if(!Paths.getPreloadPath('images/' + name + '.cea', "TEXT")) {
				name = 'icons/icon-face'; // Prevents crash from missing icon
			}

			var ceaFile:String = Paths.cea(name);
			this.reloadCEA(ceaFile, "idle");

			// Health icons are typically 2 frames. We assume the .cea has 'idle' (frame 0) and 'losing' (frame 1)
			// or we can just rely on the .cea being set up correctly for the character.
			
			// Estimate offsets based on standard 150px CitroG.WIDTH assumption
			iconOffsets[0] = (150 - 150) / 2; 
			iconOffsets[1] = (150 - 150) / 2;
			
			this.char = newChar;
		}
	}

	// Helper to manually set the frame if your .cea uses a single 'idle' animation with 2 frames
	public function setLosing(losing:Bool):Void 
	{
		// If your .cea has separate animations:
		// this.play(losing ? 'losing' : 'idle');
		
		// OR if it's a 2-frame single animation, you can force the frame:
		// this.frame = losing ? 1 : 0;
	}
}