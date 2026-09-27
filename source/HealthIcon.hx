package;

import citro.object.CitroSprite;
import citro.object.CitroObject;
import citro.CitroG;
import sys.FileSystem;

using StringTools;

class HealthIcon extends CitroSprite
{
	public var sprTracker:CitroObject = null;
	private var isOldIcon:Bool = false;
	private var isPlayer:Bool = false;
	private var char:String = '';

	private var frameWidth:Float = 150;
	private var frameHeight:Float = 150;

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super(0, 0);
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
			
			var t3xPath:String = Paths.fileExists('images/' + name + '.t3x');
			if(!FileSystem.exists(t3xPath)) {
				name = 'icons/icon-' + newChar;
				t3xPath = Paths.fileExists('images/' + name + '.t3x');
			}
			if(!FileSystem.exists(t3xPath)) {
				name = 'icons/icon-face';
			}

			this.loadGraphic(Paths.image(name));
			setLosing(false);
			this.char = newChar;
		}
	}

	public function setLosing(losing:Bool):Void {
		var frameX:Float = losing ? 150 : 0;
		var frameY:Float = 0;
		this.setSourceRect(frameX, frameY, frameWidth, frameHeight);
		this.width = frameWidth;
		this.height = frameHeight;
	}
}