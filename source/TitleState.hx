package;

#if desktop
import Discord.DiscordClient;
import sys.thread.Thread;
#end

import citro.CitroG;
import citro.state.CitroState;
import citro.object.CitroObject;
import citro.object.CitroSprite;
import citro.object.CitroAnimate;
import citro.math.CitroMath;
import citro.backend.CitroColor;
import citro.backend.CitroTimer;
import citro.backend.CitroTween;
import citro.backend.CitroTween.CitroEase;

import gamejolt.GameJolt;
import gamejolt.GJRequest;
import gamejolt.types.RequestType;
import gamejolt.formats.Trophy;

import haxe.Json;
import sys.FileSystem;
import sys.io.File;

// import options.GraphicsSettingsSubState;

using StringTools;

@:headerInclude("3ds.h")
typedef TitleData = {
	titlex:Float,
	titley:Float,
	startx:Float,
	starty:Float,
	gfx:Float,
	gfy:Float,
	backgroundSprite:String,
	bpm:Int
}

class TitleState extends MusicBeatState
{
	public static var initialized:Bool = false;

	var blackScreen:CitroSprite;
	var credGroup:Array<CitroObject> = [];
	var credTextShit:Alphabet;
	var textGroup:Array<CitroObject> = [];
	var ngSpr:CitroSprite;
	
	var titleTextColors:Array<CitroColor> = [0xFF33FFFF, 0xFF3333CC];
	var titleTextAlphas:Array<Float> = [1, .64];

	var curWacky:Array<String> = [];
	var wackyImage:CitroSprite;

	#if TITLE_SCREEN_EASTER_EGG
	var easterEggKeys:Array<String> = ['SHADOW', 'RIVER', 'SHUBS', 'BBPANZU'];
	var easterEggKeysBuffer:String = '';
	#end

	var mustUpdate:Bool = false;
	var titleJSON:TitleData;
	public static var updateVersion:String = '';

	override public function create():Void
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		#if LUA_ALLOWED
		Paths.pushGlobalMods();
		#end
		
		WeekData.loadTheFirstEnabledMod();
		PlayerSettings.init();

		curWacky = CoolUtil.getRandomObject(getIntroTextShit());

		super.create();

		CitroG.save.data('funkin', 'ninjamuffin99');
		ClientPrefs.loadPrefs();

		#if CHECK_FOR_UPDATES
		if(ClientPrefs.checkForUpdates && !closedState) {
			trace('checking for update');
			var http = new haxe.Http("https://raw.githubusercontent.com/ShadowMario/FNF-PsychEngine/main/gitVersion.txt");
			http.onData = function (data:String) {
				updateVersion = data.split('\n')[0].trim();
				var curVersion:String = MainMenuState.psychEngineVersion.trim();
				if(updateVersion != curVersion) mustUpdate = true;
			}
			http.request();
		}
		#end

		Highscore.load();

		try {
		    var jsonContent:String = Paths.getTextFromFile('images/gfDanceTitle.json');
		    var parsedJSON:TitleData = Json.parse(jsonContent);
		    
		    var scaleX = 400 / 1280;
		    var scaleY = 240 / 720;
		    
		    titleJSON = {
		        titlex: parsedJSON.titlex * scaleX,
		        titley: parsedJSON.titley * scaleY,
		        startx: parsedJSON.startx * scaleX,
		        starty: parsedJSON.starty * scaleY,
		        gfx: parsedJSON.gfx * scaleX,
		        gfy: parsedJSON.gfy * scaleY,
		        backgroundSprite: parsedJSON.backgroundSprite,
		        bpm: parsedJSON.bpm
		    };
		} catch(e:Dynamic) {
		    titleJSON = {
		        titlex: 200,
		        titley: 30,
		        startx: 200,
		        starty: 190,
		        gfx: 220,
		        gfy: 130,
		        backgroundSprite: "",
		        bpm: 102
		    };
		    trace("Using 3DS fallback title coordinates");
		}

		#if TITLE_SCREEN_EASTER_EGG
		if (CitroG.save.data.psychDevsEasterEgg == null) CitroG.save.data.psychDevsEasterEgg = '';
		switch(CitroG.save.data.psychDevsEasterEgg.toUpperCase()) {
			case 'SHADOW': titleJSON.gfx += 60; titleJSON.gfy += 15;
			case 'RIVER': titleJSON.gfx += 30; titleJSON.gfy += 10;
			case 'SHUBS': titleJSON.gfx += 50; titleJSON.gfy -= 5;
			case 'BBPANZU': titleJSON.gfx += 15; titleJSON.gfy += 30;
		}
		#end

		if(!initialized) {
			persistentUpdate = true;
			persistentDraw = true;
		}

		if (CitroG.save.data.weekCompleted != null) {
			StoryMenuState.weekCompleted = CitroG.save.data.weekCompleted;
		}

		#if FREEPLAY
		CitroG.switchState(new FreeplayState());
		#elseif CHARTING
		CitroG.switchState(new FreeplayState());
		#else
		if(CitroG.save.data.flashing == null && !FlashingState.leftState) {
			CitroG.switchState(new FlashingState());
		} else {
			#if desktop
			if (!DiscordClient.isInitialized) {
				DiscordClient.initialize();
			}
			#end

			if (initialized) {
				startIntro();
			} else {
				CitroTimer.start(1, function() { startIntro(); });
			}
		}
		#end
	}

	var logoBl:CitroAnimate;
	var gfDance:CitroAnimate;
	var danceLeft:Bool = false;
	var titleText:CitroAnimate;

	function startIntro()
	{
		if (!initialized) {
			SoundPlayer.preload(Paths.music('freakyMenu'));
		}

		Conductor.changeBPM(titleJSON.bpm);
		persistentUpdate = true;

		var bg:CitroSprite = new CitroSprite();
        bg.loadGraphic(Paths.image('menuBG'));
		CitroG.state.members.push(bg);

        gfDance = new CitroAnimate(Paths.cea('gfDanceTitle'));
        gfDance.x = titleJSON.gfx;
        gfDance.y = titleJSON.gfy;
        gfDance.scale.set(0.35, 0.35);

        logoBl = new CitroAnimate(Paths.cea('logoBumpin'));
        logoBl.x = titleJSON.titlex;
        logoBl.y = titleJSON.titley;
        logoBl.scale.set(0.35, 0.35);

		var easterEgg:String = CitroG.save.data.psychDevsEasterEgg;
		if(easterEgg == null) easterEgg = '';

		switch(easterEgg.toUpperCase()) {
			#if TITLE_SCREEN_EASTER_EGG
			case 'SHADOW': gfDance.reloadCEA(Paths.cea('ShadowBump'), 'Shadow Title Bump');
			case 'RIVER': gfDance.reloadCEA(Paths.cea('RiverBump'), 'River Title Bump');
			case 'SHUBS': gfDance.reloadCEA(Paths.cea('ShubBump'), 'Shub Title Bump');
			case 'BBPANZU': gfDance.reloadCEA(Paths.cea('BBBump'), 'BB Title Bump');
			#end
			default: gfDance.reloadCEA(Paths.cea('gfDanceTitle'), 'gfDance');
		}
		
		CitroG.state.members.push(gfDance);
		CitroG.state.members.push(logoBl);

		titleText = new CitroAnimate(Paths.cea('titleEnter'));
        titleText.x = titleJSON.startx;
        titleText.y = titleJSON.starty;
		titleText.scale.set(0.4, 0.4);
		titleText.play('idle');
		CitroG.state.members.push(titleText);

		var logo:CitroSprite = new CitroSprite();
        logo.loadGraphic(Paths.image('logo'));
		logo.scale.set(0.4, 0.4);
		logo.x = (400 - logo.width) / 2;
		logo.y = (240 - logo.height) / 2;
		CitroG.state.members.push(logo);

		credGroup = [];
		textGroup = [];

		blackScreen = new CitroSprite().makeGraphic(400, 240, CitroColor.BLACK);
		credGroup.push(blackScreen);
		CitroG.state.members.push(blackScreen);

		credTextShit = new Alphabet(0, 0, "", true);
		credTextShit.screenCenter(XY);
		credTextShit.visible = false;

		ngSpr = new CitroSprite(0, 130);
        ngSpr.loadGraphic(Paths.image('newgrounds_logo'));
		CitroG.state.members.push(ngSpr);
		ngSpr.visible = false;
		ngSpr.scale.set(0.4, 0.4);
		ngSpr.x = (400 - ngSpr.width) / 2;

		var tweenProps = new Map<String, Float>();
		tweenProps.set("y", credTextShit.y + 20);
		CitroTween.tweenObject(credTextShit, tweenProps, 2.9, {ease: CitroEase.QUAD_INOUT});

		if (initialized) {
			skipIntro();
		} else {
			initialized = true;
		}
	}

	function getIntroTextShit():Array<Array<String>> {
		try {
			var fullText:String = File.getContent(Paths.txt('introText'));
			var firstArray:Array<String> = fullText.split('\n');
			var swagGoodArray:Array<Array<String>> = [];
			for (i in firstArray) swagGoodArray.push(i.split('--'));
			return swagGoodArray;
		} catch(e:Dynamic) {
			return [["Friday Night Funkin'", "3DS Port"]];
		}
	}

	var transitioning:Bool = false;
	private static var playJingle:Bool = false;
	var newTitle:Bool = false;
	var titleTimer:Float = 0;
	var skippedIntro:Bool = false;
	public static var closedState:Bool = false;
	private var sickBeats:Int = 0;

	override function update(delta:Int):Void
	{
		var elapsed:Float = delta / 1000.0;
		Conductor.songPosition += elapsed * 1000;

		var pressedEnter:Bool = controls.ACCEPT; 

		if (newTitle) {
			titleTimer += CitroMath.clamp(elapsed, 0, 1);
			if (titleTimer > 2) titleTimer -= 2;
		}

		if (initialized && !transitioning && skippedIntro) {
			if (newTitle && !pressedEnter) {
				var timer:Float = titleTimer;
				if (timer >= 1) timer = (-timer) + 2;
				timer = timer < 0.5 ? 2 * timer * timer : 1 - Math.pow(-2 * timer + 2, 2) / 2;
				
				// titleText.color = interpolateColor(titleTextColors[0], titleTextColors[1], timer);
				titleText.alpha = CitroMath.lerp(titleTextAlphas[0], titleTextAlphas[1], timer);
			}
			
			if(pressedEnter) {
				titleText.color = CitroColor.WHITE;
				titleText.alpha = 1;
				titleText.play('press');

				SoundPlayer.playSound(Paths.sound('confirmMenu'));

				transitioning = true;
				CitroTimer.start(1, function() {
					if (mustUpdate) CitroG.switchState(new PlayState());
					else CitroG.switchState(new MainMenuState());
					closedState = true;
				});
			}
		}

		if (initialized && pressedEnter && !skippedIntro) {
			skipIntro();
		}

		super.update(delta);
	}

	function interpolateColor(from:CitroColor, to:CitroColor, t:Float):CitroColor {
		var r = Math.round(from.red + (to.red - from.red) * t);
		var g = Math.round(from.green + (to.green - from.green) * t);
		var b = Math.round(from.blue + (to.blue - from.blue) * t);
		var a = Math.round(from.alpha + (to.alpha - from.alpha) * t);
		return (a << 24) | (r << 16) | (g << 8) | b;
	}

	function createCoolText(textArray:Array<String>, ?offset:Float = 0) {
		for (i in 0...textArray.length) {
			var money:Alphabet = new Alphabet(0, 0, textArray[i], true);
			money.screenCenter(X);
			money.y += (i * 40) + 120 + offset;
			credGroup.push(money);
			textGroup.push(money);
			CitroG.state.members.push(money);
		}
	}

	function addMoreText(text:String, ?offset:Float = 0) {
		var coolText:Alphabet = new Alphabet(0, 0, text, true);
		coolText.screenCenter(X);
		coolText.y += (textGroup.length * 40) + 120 + offset;
		credGroup.push(coolText);
		textGroup.push(coolText);
		CitroG.state.members.push(coolText);
	}

	function deleteCoolText() {
		while (textGroup.length > 0) {
			var member = textGroup.shift();
			credGroup.remove(member);
			CitroG.state.members.remove(member);
			member.destroy();
		}
	}

	override function beatHit():Void
	{
		super.beatHit();

		if(gfDance != null) {
			danceLeft = !danceLeft;
			gfDance.play(danceLeft ? 'danceRight' : 'danceLeft');
		}

		if(!closedState) {
			sickBeats++;
			switch (sickBeats) {
				case 1:
					SoundPlayer.playSound(Paths.music('freakyMenu'));
				case 2:
					#if PSYCH_WATERMARKS
					createCoolText(['Psych Engine by'], 15);
					#else
					createCoolText(['ninjamuffin99', 'phantomArcade', 'kawaisprite', 'evilsk8er']);
					#end
				case 4:
					#if PSYCH_WATERMARKS
					addMoreText('Shadow Mario', 15);
					addMoreText('RiverOaken', 15);
					addMoreText('shubs', 15);
					#else
					addMoreText('present');
					#end
				case 5: deleteCoolText();
				case 6:
					#if PSYCH_WATERMARKS
					createCoolText(['Not associated', 'with'], -40);
					#else
					createCoolText(['In association', 'with'], -40);
					#end
				case 8:
					addMoreText('newgrounds', -40);
					ngSpr.visible = true;
				case 9:
					deleteCoolText();
					ngSpr.visible = false;
				case 10: createCoolText([curWacky[0]]);
				case 12: addMoreText(curWacky[1]);
				case 13: deleteCoolText();
				case 14: addMoreText('Friday');
				case 15: addMoreText('Night');
				case 16: addMoreText('Funkin');
				case 17: skipIntro();
			}
		}
	}

	function skipIntro():Void
	{
		if (!skippedIntro) {
			CitroG.state.members.remove(ngSpr);
			deleteCoolText();
			
			if (playJingle) {
				transitioning = true;
				CitroTimer.start(3.2, function() {
					transitioning = false;
				});
				playJingle = false;
			}
			skippedIntro = true;
		}
	}
}
