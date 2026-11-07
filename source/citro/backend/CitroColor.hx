package citro.backend;

import citro.math.CitroMath;
import cpp.UInt8;
import cpp.UInt32;

/**
 * Advanced coloring options.
 */
enum abstract CitroColor(UInt32) from UInt32 to UInt32 {
    public static inline var WHITE:CitroColor = 0xFFFFFFFF;
    public static inline var BLACK:CitroColor = 0xFF000000;
    public static inline var RED:CitroColor = 0xFFFF0000;
    public static inline var GREEN:CitroColor = 0xFF00FF00;
    public static inline var BLUE:CitroColor = 0xFF0000FF;
	public static inline var YELLOW:CitroColor = 0xFFFFFF00;
	public static inline var ORANGE:CitroColor = 0xFFFFA500;
	public static inline var GRAY:CitroColor = 0xFF808080;
    public static inline var TRANSPARENT:CitroColor = 0x00000000;

    public var alpha(get, set):UInt8;
    function get_alpha():UInt8 return (this >> 24) & 0xFF;
    inline function set_alpha(alpha:UInt8):UInt8 {
        this &= 0x00ffffff;
        this |= Std.int(CitroMath.clamp(alpha, 0, 0xFF)) << 24;
        return alpha;
    }

    public var red(get, set):UInt8;
    function get_red():UInt8 return (this >> 16) & 0xFF;
    inline function set_red(red:UInt8):UInt8 {
        this &= 0xff00ffff;
        this |= Std.int(CitroMath.clamp(red, 0, 0xFF)) << 16;
        return red;
    }

    public var green(get, set):UInt8;
    function get_green():UInt8 return (this >> 8) & 0xFF;
    inline function set_green(green:UInt8):UInt8 {
        this &= 0xffff00ff;
        this |= Std.int(CitroMath.clamp(green, 0, 0xFF)) << 8;
        return green;
    }

    public var blue(get, set):UInt8;
    function get_blue():UInt8 return this & 0xFF;
    inline function set_blue(blue:UInt8):UInt8 {
        this &= 0xffffff00;
        this |= Std.int(CitroMath.clamp(blue, 0, 0xFF));
        return blue;
    }

    public static inline function fromRGB(r:Int, g:Int, b:Int, a:Int = 255):CitroColor {
        return (Std.int(CitroMath.clamp(a, 0, 0xFF)) << 24) |
               (Std.int(CitroMath.clamp(r, 0, 0xFF)) << 16) |
               (Std.int(CitroMath.clamp(g, 0, 0xFF)) << 8) |
               Std.int(CitroMath.clamp(b, 0, 0xFF));
    }

    public static function fromHSV(h:Float, s:Float, v:Float, a:Int = 255):CitroColor {
        var c = v * s;
        var x = c * (1 - Math.abs((h / 60) % 2 - 1));
        var m = v - c;
        var r = 0.0, g = 0.0, b = 0.0;

        if (h >= 0 && h < 60) { r = c; g = x; b = 0; }
        else if (h >= 60 && h < 120) { r = x; g = c; b = 0; }
        else if (h >= 120 && h < 180) { r = 0; g = c; b = x; }
        else if (h >= 180 && h < 240) { r = 0; g = x; b = c; }
        else if (h >= 240 && h < 300) { r = x; g = 0; b = c; }
        else if (h >= 300 && h < 360) { r = c; g = 0; b = x; }

        return fromRGB(Std.int((r + m) * 255), Std.int((g + m) * 255), Std.int((b + m) * 255), a);
    }

    public static function lerp(from:CitroColor, to:CitroColor, t:Float):CitroColor {
        final clampedT = CitroMath.clamp(t, 0.0, 1.0);
        final r = Std.int(from.red + (to.red - from.red) * clampedT);
        final g = Std.int(from.green + (to.green - from.green) * clampedT);
        final b = Std.int(from.blue + (to.blue - from.blue) * clampedT);
        final a = Std.int(from.alpha + (to.alpha - from.alpha) * clampedT);
        return fromRGB(r, g, b, a);
    }

    public function toHexStr(includeAlpha:Bool = false):String {
        if (includeAlpha) {
            return '#' + StringTools.hex(this, 8);
        }
        return '#' + StringTools.hex(this & 0x00FFFFFF, 6);
    }

    public function toString():String {
        return toHexStr(true);
    }
}
