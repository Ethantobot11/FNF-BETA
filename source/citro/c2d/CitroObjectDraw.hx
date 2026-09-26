package citro.c2d;

import citro.backend.CitroColor;

@:headerCode('
#include <citro2d.h>
#include <citro3d.h>
')

@:cppFileCode('
#include <citro2d.h>
#include "citro/CitroGame.h"
#include "citro/object/CitroSprite.h"

static inline u32 colorConvert(int color) {
    return C2D_Color32(
        (color >> 16) & 0xFF,
        (color >> 8) & 0xFF,
        color & 0xFF,
        (color >> 24) & 0xFF
    );
}
')

class CitroObjectDraw {

	public static function drawTriangle(arrayX:Array<Float>, arrayY:Array<Float>, arrayC:Array<CitroColor>):Bool {
		if (arrayX.length > 2 && arrayY.length > 2 && arrayC.length > 0) {
			while (arrayC.length < 3) {
				arrayC.push(arrayC[0]);
			}

			untyped __cpp__('
				C2D_DrawTriangle(
					arrayX->__get(0), arrayY->__get(0), colorConvert(arrayC->__get(0)),
					arrayX->__get(1), arrayY->__get(1), colorConvert(arrayC->__get(1)),
					arrayX->__get(2), arrayY->__get(2), colorConvert(arrayC->__get(2)),
					1
				)
			');
			return true;
		}
		return false;
	}

	public static function drawLine(arrayX:Array<Float>, arrayY:Array<Float>, arrayC:Array<CitroColor>, thickness:Float = 4):Bool {
		if (arrayX.length > 1 && arrayY.length > 1 && arrayC.length > 1) {
			if (arrayC.length == 1) {
				arrayC.push(arrayC[0]);
			}

			untyped __cpp__('
				C2D_DrawLine(
					arrayX->__get(0), arrayY->__get(0), colorConvert(arrayC->__get(0)),
					arrayX->__get(1), arrayY->__get(1), colorConvert(arrayC->__get(1)),
					thickness, 1
				)
			');
			return true;
		}
		return false;
	}

	public static function drawRect(x:Float, y:Float, w:Float, h:Float, color:Array<CitroColor>):Bool {
		return color.length > 1 ? {
			while (color.length < 4)
				color.push(color[0]);
			untyped __cpp__('
				C2D_DrawRectangle(
					x, y, 1, w, h, colorConvert(color->__get(0)), colorConvert(color->__get(1)),
					colorConvert(color->__get(2)), colorConvert(color->__get(3))
				)
			');
			true;
		} : false;
	}
	
	public static function drawCircle(x:Float, y:Float, radius:Float, color:Array<CitroColor>):Bool {
		if (color.length == 0)
			return false;
		
		while (color.length < 4)
			color.push(color[0]);

		untyped __cpp__('
			C2D_DrawCircle(x, y, 1, radius, colorConvert(color->__get(0)), colorConvert(color->__get(1)), colorConvert(color->__get(2)), colorConvert(color->__get(3)))
		');
		return true;
	}

	public static function drawEllipse(x:Float, y:Float, w:Float, h:Float, color:Array<CitroColor>):Bool {
		if (color.length == 0)
			return false;
		
		while (color.length < 4)
			color.push(color[0]);
	
		untyped __cpp__('
			C2D_DrawEllipse(x, y, 1, w, y, colorConvert(color->__get(0)), colorConvert(color->__get(1)), colorConvert(color->__get(2)), colorConvert(color->__get(3)))
		');
		return true;
	}
}
