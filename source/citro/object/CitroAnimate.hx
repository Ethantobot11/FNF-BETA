package citro.object;

#if (!wiiu || !cafe)

import sys.io.File;
import citro.object.CitroSprite;
import citro.object.CitroObject;
import citro.object.CitroAtlas;
import citro.CitroG;

using StringTools;

typedef CitroFrame = {
    var srcX:Float;
    var srcY:Float;
    var srcWidth:Float;
    var srcHeight:Float;
    var offsetX:Float;
    var offsetY:Float;
    var frameWidth:Float;
    var frameHeight:Float;
}

class CitroAnimate extends CitroObject {
    var timeLeft:Float = 0;
    public var frames:Map<String, CitroFrame>;
    public var atlasSprite:CitroSprite = null;
    var atlasPath:String = "";

    public var framerate:Float = 24;
    public var frame:Int = 0;
    public var curAnim:String = "";
    public var finished:Bool = false;
    public var looped:Bool = false;
    public var animations:Map<String, Array<Int>>;

    public function new(?ceaFile:String, defaultAnim:String = "") {
        super();
        frames = new Map();
        animations = new Map();
        if (ceaFile != null) {
            loadCEA(ceaFile, defaultAnim);
        }
    }

    function loadCEA(ceaFile:String, defaultAnim:String):Void {
        if (atlasSprite != null) { atlasSprite.destroy(); atlasSprite = null; }
        frames = new Map();
        animations = new Map();
        atlasPath = "";

        try {
            final file:String = File.getContent(ceaFile);
            var dir:String = ceaFile.substr(0, ceaFile.lastIndexOf("/"));
            if (dir == "") dir = ".";

            if (file != "") {
                var firstAnimFound:String = "";
                for (line in file.split("\n")) {
                    line = line.trim();
                    if (line == "" || line.startsWith("#")) continue; 
                    
                    final row:Array<String> = line.split("?");
                    if (row.length < 10) continue;

                    final atlasFile:String = row[0].trim();
                    final srcX:Float = Std.parseFloat(row[1]);
                    final srcY:Float = Std.parseFloat(row[2]);
                    final srcWidth:Float = Std.parseFloat(row[3]);
                    final srcHeight:Float = Std.parseFloat(row[4]);
                    final offsetX:Float = Std.parseFloat(row[5]);
                    final offsetY:Float = Std.parseFloat(row[6]);
                    final frameWidth:Float = Std.parseFloat(row[7]);
                    final frameHeight:Float = Std.parseFloat(row[8]);
                    final fullKey:String = row[9].trim();

                    if (atlasPath == "") {
                        atlasPath = '$dir/$atlasFile';
                        atlasSprite = new CitroSprite();
                        if (!atlasSprite.loadGraphic(atlasPath)) {
                            atlasSprite.destroy();
                            atlasSprite = null;
                            return; 
                        }
                    }

                    var separatorIndex:Int = fullKey.lastIndexOf("-");
                    if (separatorIndex == -1) separatorIndex = fullKey.lastIndexOf("_");
                    final animName:String = separatorIndex != -1 ? fullKey.substr(0, separatorIndex) : fullKey;
                    if (firstAnimFound == "") firstAnimFound = animName;

                    frames.set(fullKey, {
                        srcX: srcX, srcY: srcY, srcWidth: srcWidth, srcHeight: srcHeight,
                        offsetX: offsetX, offsetY: offsetY, frameWidth: frameWidth, frameHeight: frameHeight
                    });
                }
                if (defaultAnim == "") defaultAnim = firstAnimFound;
            }
            play(defaultAnim);
        } catch (e:Dynamic) {
            trace("⚠️ CRITICAL: Could not load CEA file: " + ceaFile);
            trace("️ Error: " + e);
            trace("⚠️ Creating a magenta placeholder to prevent crash.");
            
            atlasSprite = new CitroSprite();
            atlasSprite.makeGraphic(32, 32, 0xFFFF00FF);
            frames.set("placeholder-0", { srcX: 0, srcY: 0, srcWidth: 32, srcHeight: 32, offsetX: 0, offsetY: 0, frameWidth: 32, frameHeight: 32 });
            play("placeholder");
        }
    }
    
    /**
     * Load multiple animations from a single T3X atlas (Grid-based)
     * @param t3xPath Path to the T3X file
     * @param frameWidth Width of each frame
     * @param frameHeight Height of each frame
     * @param animDefs Animation definitions: [animName => [frameIndices]]
     */
    public function loadFromT3XWithAnims(t3xPath:String, frameWidth:Float, frameHeight:Float, animDefs:Map<String, Array<Int>>):Void {
        if (atlasSprite != null) { atlasSprite.destroy(); atlasSprite = null; }
        frames = new Map();
        animations = new Map();
        atlasPath = t3xPath;
        
        atlasSprite = new CitroSprite();
        if (!atlasSprite.loadGraphic(t3xPath, frameWidth, frameHeight)) {
            atlasSprite.destroy();
            atlasSprite = null;
            trace("ERROR: Failed to load T3X file: " + t3xPath);
            return;
        }

        var framesPerRow:Int = Std.int(atlasSprite.sheetWidth / frameWidth);
        var framesPerCol:Int = Std.int(atlasSprite.sheetHeight / frameHeight);
        var maxFrames:Int = framesPerRow * framesPerCol;     
        
        for (i in 0...maxFrames) {
            final frameKey:String = 'frame-$i';
            var frameX:Int = i % framesPerRow;
            var frameY:Int = Std.int(i / framesPerRow);
            
            final srcX:Float = frameX * frameWidth;
            final srcY:Float = frameY * frameHeight;
            
            frames.set(frameKey, {
                srcX: srcX,
                srcY: srcY,
                srcWidth: frameWidth,
                srcHeight: frameHeight,
                offsetX: 0,
                offsetY: 0,
                frameWidth: frameWidth,
                frameHeight: frameHeight
            });
        }
        
        for (animName => frameIndices in animDefs) {
            animations.set(animName, frameIndices);
        }
        
        for (animName in animDefs.keys()) {
            play(animName);
            break;
        }
    }

    public function reloadCEA(ceaFile:String, defaultAnim:String):Void {
        if (atlasSprite != null) { atlasSprite.destroy(); atlasSprite = null; }
        frames = new Map();
        animations = new Map();
        atlasPath = "";
        loadCEA(ceaFile, defaultAnim);
    }
    
    public function loadFromAtlas(atlas:CitroAtlas, animPrefix:String, totalFrames:Int):Void {
        if (atlasSprite != null) { atlasSprite.destroy(); atlasSprite = null; }
        frames = new Map();
        animations = new Map();
        atlasPath = atlas.texturePath;
        
        atlasSprite = new CitroSprite();
        if (!atlasSprite.loadGraphic(atlasPath)) {
            atlasSprite.destroy();
            atlasSprite = null;
            return;
        }

        for (i in 0...totalFrames) {
            final frameName = '$animPrefix$i';
            final rect = atlas.getFrame(frameName);
            if (rect != null) {
                frames.set(frameName, {
                    srcX: rect.x, srcY: rect.y, srcWidth: rect.w, srcHeight: rect.h,
                    offsetX: 0, offsetY: 0, frameWidth: rect.w, frameHeight: rect.h
                });
            }
        }
        play(animPrefix);
    }

    public function addAnim(name:String, frames:Array<Int>):Void {
        animations.set(name, frames);
    }

    public function play(animation:String):Bool {
        if (isDestroyed || atlasSprite == null) return false;
        if (animations.exists(animation)) {
            curAnim = animation;
            frame = 0;
            timeLeft = 1000 / framerate;
            finished = false;
            
            final frameIndices = animations[animation];
            if (frameIndices.length > 0) {
                final frameKey = 'frame-${frameIndices[0]}';
                if (frames.exists(frameKey)) {
                    final frm = frames[frameKey];
                    width = frm.frameWidth;
                    height = frm.frameHeight;
                    return true;
                }
            }
        }
        
        final animFormat:String = '$animation-0';
        
        if (frames.exists(animFormat)) {
            timeLeft = 1000 / framerate;
            finished = false;
            curAnim = animation;
            frame = 0;
            final frm = frames[animFormat];
            width = frm.frameWidth;
            height = frm.frameHeight;
            return true;
        }
        
        var foundAny = false;
        for (key => value in frames) {
            if (key.startsWith('$animation-')) {
                curAnim = animation;
                frame = 0;
                timeLeft = 1000 / framerate;
                finished = false;
                width = value.frameWidth;
                height = value.frameHeight;
                foundAny = true;
                break;
            }
        }
        
        if (!foundAny) {
            trace("WARNING: Animation '" + animation + "' not found!");
            return false; 
        }
        
        return true;
    }

    inline function format():String {
        if (animations.exists(curAnim)) {
            final frameIndices = animations[curAnim];
            final actualFrame = frame < frameIndices.length ? frameIndices[frame] : frameIndices[frameIndices.length - 1];
            return 'frame-$actualFrame';
        }
        return '${curAnim}-$frame';
    }

    override function update():Bool {
        if (isDestroyed || atlasSprite == null) return false;
        if (!visible || alpha <= 0) return false;
        super.update(); 

        if ((timeLeft -= CitroG.deltaTime) < 1) {
            timeLeft = 1000 / framerate;
            frame++;
            var maxFrame:Int = 0;
            if (animations.exists(curAnim)) {
                maxFrame = animations[curAnim].length;
            } else {
                for (key in frames.keys()) {
                    if (key.startsWith('$curAnim-')) {
                        maxFrame++;
                    }
                }
            }
            
            if (frame >= maxFrame) {
                finished = true;
                frame = looped ? 0 : maxFrame - 1;
            }
        }

        final frameKey = format();
        if (frames.exists(frameKey) && visible) {
            final frm = frames[frameKey];
            width = frm.frameWidth;
            height = frm.frameHeight;
            atlasSprite.x = x - frm.offsetX;
            atlasSprite.y = y - frm.offsetY;
            atlasSprite.scale.x = scale.x;
            atlasSprite.scale.y = scale.y;
            atlasSprite.alpha = alpha;
            atlasSprite.color = color;
            atlasSprite.setSourceRect(frm.srcX, frm.srcY, frm.srcWidth, frm.srcHeight);
            
            return atlasSprite.update();
        }

        return false;
    }

    override function destroy() {
        if (atlasSprite != null) { atlasSprite.destroy(); atlasSprite = null; }
        frames = new Map();
        animations = new Map();
        super.destroy();
    }
}
#end
