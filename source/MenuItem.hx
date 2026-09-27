package;

import citro.object.CitroSprite;
import citro.math.CitroMath;
import citro.backend.CitroColor;
import citro.CitroG;

class MenuItem extends CitroSprite
{
	public var targetY:Float = 0;
	public var flashingInt:Int = 0;
	private var isFlashing:Bool = false;

	public function new(x:Float, y:Float, weekName:String = '')
	{
		super(x, y);
		loadGraphic(Paths.image('storymenu/' + weekName));
	}

	public function startFlashing():Void {
		isFlashing = true;
	}

	override function update():Bool
	{
		var elapsed:Float = CitroG.deltaTime / 1000.0;
		this.y = CitroMath.lerp(this.y, (targetY * 120) + 480, CitroMath.clamp(elapsed * 10.2, 0, 1));

		if (isFlashing) {
			flashingInt += 1;
			if (flashingInt % 6 >= 3) this.color = 0xFF33ffff;
			else this.color = CitroColor.WHITE;
		}
		return super.update();
	}
}