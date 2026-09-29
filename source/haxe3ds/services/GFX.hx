package haxe3ds.services;

@:headerInclude("3ds.h")
class GFX {
    public static function init():Void {
        untyped __cpp__('gfxInitDefault()');
    }

    public static var current3D(get, set):Bool;
    static function get_current3D():Bool {
        return untyped __cpp__('gfxIs3D()');
    }
    static function set_current3D(current3D):Bool {
        untyped __cpp__('gfxSet3D(current3D)');
        return current3D;
    }

    public static var isWide(get, set):Bool;
    static function get_isWide():Bool {
        return untyped __cpp__('gfxIsWide()');
    }
    static function set_isWide(isWide):Bool {
        untyped __cpp__('gfxSetWide(isWide)');
        return isWide;
    }

    public static function exit():Void {
        untyped __cpp__('gfxExit()');
    }
}