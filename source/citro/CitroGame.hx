package citro;

#if (!wiiu || !cafe)

import citro.backend.CitroTimer;
import citro.backend.CitroTween;
import citro.state.CitroState;

import haxe3ds.applet.Error;
import haxe3ds.services.APT;
import haxe3ds.services.GFX;
import haxe3ds.services.RomFS;
import haxe3ds.OS;

import cpp.UInt64;

/**
 * Literally everything to set up citro engine.
 */
@:headerCode("
#include <citro2d.h>
#include <citro3d.h>
extern C3D_RenderTarget* topScreen;
extern C3D_RenderTarget* bottomScreen;
")

@:cppFileCode('
C3D_RenderTarget* topScreen = nullptr;
C3D_RenderTarget* bottomScreen = nullptr;
')
class CitroGame {
	@:noCompletion
	public static var _shouldQuit:Bool = false;

	static function renderObjectsForScreen(state:CitroState, bottom:Bool) {
		for (member in state.members) {
			if (member == null) continue;
			
			if (member.isDestroyed) {
				state.members.remove(member);
				continue;
			}

			if (member.bottom != bottom) continue;
			member.update();
		}
	}

	static function renderState(state:CitroState) {
		for (i in 0...2) {
			untyped __cpp__("C2D_SceneBegin({0} == 0 ? topScreen : bottomScreen)", i);
			renderObjectsForScreen(state, i == 1);
		}
	}

	public static function start(state:CitroState) {
		if (state == null) {
			return;
		}

		GFX.init();
		RomFS.init();

		untyped __cpp__('
			C2D_Init(C2D_DEFAULT_MAX_OBJECTS);
			C3D_Init(C3D_DEFAULT_CMDBUF_SIZE);
			C2D_Prepare();

			topScreen = C2D_CreateScreenTarget(GFX_TOP,	GFX_LEFT);
			bottomScreen = C2D_CreateScreenTarget(GFX_BOTTOM, GFX_LEFT);
		');

		(CitroG.state = state).create();
		while (APT.mainLoop() && !_shouldQuit) {
			final startTime = OS.time.toInt();

			untyped __cpp__('
				C3D_FrameBegin(C3D_FRAME_SYNCDRAW);
				C2D_TargetClear(topScreen, 0xFF1D1D24);
				C2D_TargetClear(bottomScreen, 0xFF000000);
			');

			CitroTween.update();
			CitroTimer.update();
			CitroG.state.update(CitroG.deltaTime);

			final sub = CitroG.substate;
			if (sub != null) {
				sub.update(CitroG.deltaTime);
			}

			renderState(CitroG.state);
			if (sub != null) {
				renderState(sub);
			}

			untyped __cpp__('
				C2D_Flush();
				C3D_FrameEnd(0);
			');

			var elapsed = OS.time.toInt() - startTime;

			if (elapsed < 1) elapsed = 1;
			if (elapsed > 33) elapsed = 33; 
			
			CitroG.deltaTime = elapsed;
		}

		untyped __cpp__('
			C3D_Fini();
			C2D_Fini();
		');

		RomFS.exit();
		GFX.exit();
	}
	#end
}