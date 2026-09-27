package;

import citro.object.CitroSprite;

using StringTools;

class AttachedSprite extends CitroSprite
{
	public var sprTracker:CitroSprite;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;
	public var angleAdd:Float = 0;
	public var alphaMult:Float = 1;

	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;
	public var copyVisible:Bool = false;

	public function new(?file:String = null, ?anim:String = null, ?library:String = null, ?loop:Bool = false)
	{
		super(0, 0);
		if(file != null) {
			this.loadGraphic(Paths.image(file));
		}
		this.antialiasing = ClientPrefs.globalAntialiasing;
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