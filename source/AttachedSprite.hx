package;

import citro.object.CitroText;
import citro.object.CitroSprite;

class AttachedSprite extends CitroSprite
{
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var sprTracker:CitroSprite;
	public var copyVisible:Bool = true;
	public var copyAlpha:Bool = false;

	public function new(text:String = "", ?offsetX:Float = 0, ?offsetY:Float = 0, ?bold:Bool = false, ?scale:Float = 1)
	{
		super(0, 0, text);
		this.scale.set(scale, scale);
		this.offsetX = offsetX;
		this.offsetY = offsetY;
	}

	override public function update():Bool
	{
		if (sprTracker != null) {
			this.x = sprTracker.x + offsetX;
			this.y = sprTracker.y + offsetY;
			if(copyVisible) {
				this.visible = sprTracker.visible;
			}
			if(copyAlpha) {
				this.alpha = sprTracker.alpha;
			}
		}
		return super.update();
	}
}