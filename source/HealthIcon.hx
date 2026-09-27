package;

import citro.object.CitroAnimate;
import citro.CitroG;
import sys.io.File;
import sys.FileSystem;

using StringTools;

class HealthIcon extends CitroAnimate
{
	public var sprTracker:CitroObject = null;
	private var isOldIcon:Bool = false;
	private var isPlayer:Bool = false;
	private var char:String = '';

	private var iconOffsets:Array<Float> = [0, 0];

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super("");
		this.x = 0;
		this.y = 0;
		this.isOldIcon = (char == 'bf-old');
		this.isPlayer = isPlayer;
		changeIcon(char);
	}

	override public function update():Bool
	{
		if (sprTracker != null) {
			this.x = sprTracker.x + sprTracker.width + 12;
			this.y = sprTracker.y - 30;
		}
		return super.update();
	}

	public function swapOldIcon():Void {
		isOldIcon = !isOldIcon;
		if(isOldIcon) changeIcon('bf-old');
		else changeIcon('bf');
	}

	public function changeIcon(newChar:String):Void {
		if(this.char != newChar) {
			var name:String = 'icons/' + newChar;
			
			if(!FileSystem.exists(Paths.getPreloadPath('images/' + name + '.cea'))) {
				name = 'icons/icon-' + newChar;
			}
			if(!FileSystem.exists(Paths.getPreloadPath('images/' + name + '.cea'))) {
				name = 'icons/icon-face';
			}

			var ceaFile:String = Paths.cea(name);
			this.reloadCEA(ceaFile, "idle");
			
			iconOffsets[0] = 0; 
			iconOffsets[1] = 0;
			
			this.char = newChar;
		}
	}

	public function setLosing(losing:Bool):Void {
		// this.frame = losing ? 1 : 0; // Uncomment if your .cea uses frames for losing state
	}
}