package;

import citro.object.CitroObject;
import citro.object.CitroSprite;

using StringTools;

class AttachedSprite extends CitroObject
{
	public var sprTracker:CitroObject;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;
	public var angleAdd:Float = 0;
	public var alphaMult:Float = 1;

	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;
	public var copyVisible:Bool = false;

	private var sprite:CitroSprite;

	public function new(?file:String = null)
	{
		super();
		if(file != null) {
			sprite = new CitroSprite(0, 0);
			sprite.loadGraphic(Paths.image(file));
			sprite.antialiasing = ClientPrefs.globalAntialiasing;
			this.addChild(sprite);
		}
	}

	override public function update():Bool
	{
		if (sprTracker != null) {
			this.x = sprTracker.x + xAdd;
			this.y = sprTracker.y + yAdd;

			if(copyAngle)
				this.angle = sprTracker.angle + angleAdd;

			if(copyAlpha)
				this.alpha = sprTracker.alpha * alphaMult;

			if(copyVisible) 
				this.visible = sprTracker.visible;
		}
		return super.update();
	}
}