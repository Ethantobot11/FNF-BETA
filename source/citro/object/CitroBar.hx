package citro.object;

import citro.backend.CitroColor;

class CitroBar extends CitroSprite {
    public var min:Float = 0;
    public var max:Float = 100;
    public var value:Float = 0;

    public function new(x:Float, y:Float, width:Float, height:Float) {
        super(x, y);
        makeGraphic(width, height, 0xFF464646);
        scale.x = 1.0;
    }

    public function updateBar():Void {
        var pct = (value - min) / (max - min);
        if (pct < 0) pct = 0;
        if (pct > 1) pct = 1;
        scale.x = pct;
    }
}