package citro.object;

import citro.object.CitroObject;
import citro.math.CitroMath;

/**
 * A backend for camera only, useful if you wanna make a camera like view.
 * * Note: It is a object, so it must be added from this state!
 * * @since 1.1.0
 */
@:cppInclude("citro/CitroGame.h")
@:cppInclude("3ds.h")
class CitroCamera extends CitroObject {
	/**
	 * Don't use this.
	 */
	var curX:Float = 0;
	var curY:Float = 0;
	var bottomCam:Bool = false;
	var scX:Int = 0;

	/**
	 * Target object for the camera to continuously follow automatically.
	 */
	public var target:CitroObject = null;

	/**
	 * Lists of members currently added in this Camera.
	 */
	public var members:Array<CitroObject> = [];

	/**
	 * Per update lerping to update X and Y's Position.
	 */
	public var lerp:Float = 0.5;

	/**
	 * Current zoom usage.
	 */
	public var zoom:Float = 1;

	/**
	 * Constructor for making the camera.
	 * @param bottom Whetever or not the camera positions at the bottom.
	 */
	public function new(bottom:Bool = false) {
		super();

		bottomCam = bottom;
		scX = bottom ? 160 : 200;
	}

	override function update():Bool {
		if (target != null) {
			x = target.x - (bottomCam ? 160 : 200) + (target.width / 2);
			y = target.y - 120 + (target.height / 2);
		}

		super.update();

		curX = CitroMath.lerp(curX, x, lerp);
		curY = CitroMath.lerp(curY, y, lerp);
		bottom = bottomCam;

		untyped __cpp__('
			C3D_Mtx camMtx;
			Mtx_Diagonal(&camMtx, 1.0f, 1.0f, 1.0f, 1.0f);
			C2D_ViewSave(&camMtx);
			C2D_ViewTranslate((Float){0}, 120.0f);
			C2D_ViewScale({1}, {1});
			C2D_ViewTranslate(-(Float){2} - (Float){0}, -(Float){3} - 120.0f);
		', scX, zoom, curX, curY);

		for (spr in members) {
			if (spr == null) continue;
			if (spr.isDestroyed) {
				members.remove(spr);
				continue;
			}
			if (!spr.visible || spr.alpha <= 0) continue;
			spr.update();
		}

		untyped __cpp__('C2D_ViewRestore(&camMtx)');

		return true;
	}

	/**
	 * Kept for backwards compatibility; now just draws the object in world space.
	 */
	public function renderObj(spr:CitroObject):Bool {
		if (spr == null) return false;
		return spr.update();
	}

	/**
	 * Follows the object and sets the position to the object's position.
	 */
	public function follow(object:CitroObject, persistent:Bool = false) {
		if (object != null) {
			x = object.x - (bottomCam ? 160 : 200) + (object.width / 2);
			y = object.y - 120 + (object.height / 2);
		}
		if (persistent) {
			target = object;
		}
	}

	/**
	 * Adds a CitroObject to camera and displays it every frame if you call `update`.
	 */
	public function add(member:CitroObject) {
		members.push(member);
	}

	/**
	 * Inserts a CitroObject to a layer index specified.
	 */
	public function insert(index:Int, member:CitroObject) {
		members.insert(index, member);
	}

	/**
	 * Will destroy every sprite from camera and cleans memory.
	 */
	override function destroy() {
		super.destroy();
		for (member in members) {
			member.destroy();
		}
		members = [];
	}
}
