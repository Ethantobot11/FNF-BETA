package citro.object;

#if (!wiiu || !cafe)

import citro.CitroG;
import citro.backend.CitroColor;

@:headerCode('
#include <3ds.h>
#include <citro2d.h>
#include <citro3d.h>
')

@:headerInclude("citro/object/CitroVector2D.h")
@:headerClassCode('
    C2D_SpriteSheet ss;
    C2D_Image image;
    int currentFrame;
')

class CitroSprite extends CitroObject {
    
    public var srcX:Float = 0;
    public var srcY:Float = 0;
    public var srcWidth:Float = 0;
    public var srcHeight:Float = 0;
    public var useSrcRect:Bool = false;
    public var frame(default, set):Int = 0;
    public var totalFrames(default, null):Int = 0;
    public var sheetWidth:Float = 0;
    public var sheetHeight:Float = 0;
    public var flipX:Bool = false;
    public var flipY:Bool = false;

    public function new(x:Float = 0, y:Float = 0) {
        super();
        this.x = x;
        this.y = y;
        untyped __cpp__('
            this->ss = nullptr;
            this->image.tex = nullptr;
            this->image.subtex = nullptr;
            this->currentFrame = 0;
        ');
    }

    inline public function makeGraphic(Width:Float, Height:Float, Col:CitroColor = 0xFFFFFFFF):CitroSprite {
        width  = Width;
        height = Height;
        color  = Col;
        return this;
    }

    public function setSourceRect(x:Float, y:Float, w:Float, h:Float):Bool {
        srcX = x;
        srcY = y;
        srcWidth = w;
        srcHeight = h;
        useSrcRect = true;
        width = w;
        height = h;
        return true;
    }

    public function loadGraphic(file:String, ?frameWidth:Float = 0, ?frameHeight:Float = 0):Bool {
        if (CitroG.caches.exists(file)) {
            var cachedPtr = CitroG.caches.get(file);
            if (cachedPtr != null) {
                untyped __cpp__('this->ss = (C2D_SpriteSheet){0}', cachedPtr);
                var cachedFrames = CitroG.caches.getMeta(file + "_frames");
                if (cachedFrames != null) {
                    totalFrames = cachedFrames;
                }
            } else {
                CitroG.caches.remove(file);
                CitroG.caches.remove(file + "_frames");
            }
        }
        
        if (!CitroG.caches.exists(file)) {
            untyped __cpp__('
                this->ss = C2D_SpriteSheetLoad(file.c_str());
                if (!this->ss) return false;
                this->totalFrames = C2D_SpriteSheetCount(this->ss);
            ');
            CitroG.caches.set(file, untyped __cpp__('this->ss'));
            CitroG.caches.setMeta(file + "_frames", totalFrames);
        }

        var hasValidSheet:Bool = false;
        untyped __cpp__('hasValidSheet = (this->ss != nullptr);');
        if (!hasValidSheet) {
            trace("ERROR: Sprite sheet is null after loading: " + file);
            return false;
        }

        var imageWidth:Float = 0;
        var imageHeight:Float = 0;
        untyped __cpp__('
            C2D_Image firstImg = C2D_SpriteSheetGetImage(this->ss, 0);
            if (firstImg.subtex != NULL) {
                imageWidth = firstImg.subtex->width;
                imageHeight = firstImg.subtex->height;
            }
        ');
        sheetWidth = imageWidth;
        sheetHeight = imageHeight;
        
        if (frameWidth > 0 && frameHeight > 0) {
            width = frameWidth;
            height = frameHeight;         
            var framesPerRow:Int = Std.int(sheetWidth / frameWidth);
            var framesPerCol:Int = Std.int(sheetHeight / frameHeight);
            totalFrames = framesPerRow * framesPerCol;
            trace("DEBUG loadGraphic: file=" + file + " | sheetWidth=" + sheetWidth + " | frameWidth=" + frameWidth + " | totalFrames=" + totalFrames);         
            CitroG.caches.setMeta(file + "_frames", totalFrames);
        } else {
            width = sheetWidth;
            height = sheetHeight;
        }
        
        setFrame(0);
        return true;
    }

    public function setFrame(frameIndex:Int):Void {
        if (frameIndex < 0 || frameIndex >= totalFrames) {
            trace('Warning: Frame $frameIndex out of range (0-${totalFrames - 1})');
            return;
        }
        
        frame = frameIndex;
        untyped __cpp__('
            this->currentFrame = {0};
            this->image = C2D_SpriteSheetGetImage(this->ss, {0});
        ', frameIndex);
    }

    function set_frame(value:Int):Int {
        if (value != frame) setFrame(value);
        return value;
    }

    public function loadGraphicFromSprite(Sprite:CitroSprite):Bool {
        if (Sprite == null) return false;
        
        untyped __cpp__('
            this->ss = Sprite->ss;
            this->image = Sprite->image;
            this->currentFrame = Sprite->currentFrame;
            this->totalFrames = Sprite->totalFrames;
        ');
        
        width = Sprite.width;
        height = Sprite.height;
        sheetWidth = Sprite.sheetWidth;
        sheetHeight = Sprite.sheetHeight;
        frame = Sprite.frame;
        srcX = Sprite.srcX;
        srcY = Sprite.srcY;
        srcWidth = Sprite.srcWidth;
        srcHeight = Sprite.srcHeight;
        useSrcRect = Sprite.useSrcRect;
        flipX = Sprite.flipX;
        flipY = Sprite.flipY;
        return true;
    }

    /**
     * Draws the sprite directly at the specified coordinates without modifying the global view matrix.
     * This is much faster and safer for drawing many instances (like tilemaps).
     */
    public function drawRaw(drawX:Float, drawY:Float):Void {
        if (isDestroyed || !visible || alpha <= 0) return;
        
        untyped __cpp__('
            Float sw = this->scale->x, sh = this->scale->y;
            Float drawSw = this->flipX ? -fabs(sw) : fabs(sw);
            Float drawSh = this->flipY ? -fabs(sh) : fabs(sh);
            if (this->image.tex == NULL || this->image.subtex == NULL) {
                CONVERT_TO_COMPATIBLE_COLOR(this->color)
                C2D_DrawRectSolid({0}, {1}, 0, this->width * fabs(sw), this->height * fabs(sh), finalColor);
            } else {
                static C2D_ImageTint tint;
                C2D_PlainImageTint(
                    &tint,
                    C2D_Color32(
                        (this->color >> 16) & 0xFF,
                        (this->color >> 8) & 0xFF,
                        this->color & 0xFF,
                        ((this->color >> 24) & 0xFF) * C2D_Clamp(this->alpha, 0, 1)
                    ),
                    fabs(((Float)(this->color & 0xFFFFFF) / 16777215.0) - 1) / 2.0
                );
                if (this->useSrcRect) {
                    Tex3DS_SubTexture srcSubTex;
                    srcSubTex.width = (u16)this->srcWidth;
                    srcSubTex.height = (u16)this->srcHeight;
                    Tex3DS_SubTexture* orig = this->image.subtex;
                    float uScale = (orig->right - orig->left) / orig->width;
                    float vScale = (orig->bottom - orig->top) / orig->height;
                    srcSubTex.left = orig->left + this->srcX * uScale;
                    srcSubTex.right = orig->left + (this->srcX + this->srcWidth) * uScale;
                    srcSubTex.top = orig->top + this->srcY * vScale;
                    srcSubTex.bottom = orig->top + (this->srcY + this->srcHeight) * vScale;
                    C2D_Image drawImg = this->image;
                    drawImg.subtex = &srcSubTex;
                    C2D_DrawImageAt(drawImg, {0}, {1}, 0, &tint, drawSw, drawSh);
                } else {
                    C2D_DrawImageAt(this->image, {0}, {1}, 0, &tint, drawSw, drawSh);
                }
            }
        ', drawX, drawY);
    }

    override function update():Bool {
        if (isDestroyed || !visible || alpha <= 0) return false;
        
        untyped __cpp__('
            Float sw = this->scale->x, sh = this->scale->y;
            Float drawSw = this->flipX ? -fabs(sw) : fabs(sw);
            Float drawSh = this->flipY ? -fabs(sh) : fabs(sh);
            C3D_Mtx matrix;
            Mtx_Diagonal(&matrix, 1.0f, 1.0f, 1.0f, 1.0f);
            C2D_ViewSave(&matrix);
            C2D_ViewTranslate(this->x, this->y);
            C2D_ViewTranslate((this->width * fabs(sw)) / 2.0, (this->height * fabs(sh)) / 2.0);
            C2D_ViewRotateDegrees(this->angle);
            C2D_ViewScale(drawSw, drawSh);
            C2D_ViewTranslate(-this->width / 2.0, -this->height / 2.0);
            if (this->image.tex == NULL || this->image.subtex == NULL) {
                CONVERT_TO_COMPATIBLE_COLOR(this->color)
                C2D_DrawRectSolid(0, 0, 0, this->width, this->height, finalColor);
            } else {
                C2D_ImageTint tint;
                C2D_PlainImageTint(
                    &tint,
                    C2D_Color32(
                        (this->color >> 16) & 0xFF,
                        (this->color >> 8) & 0xFF,
                        this->color & 0xFF,
                        ((this->color >> 24) & 0xFF) * C2D_Clamp(this->alpha, 0, 1)
                    ),
                    fabs(((Float)(this->color & 0xFFFFFF) / 16777215.0) - 1) / 2.0
                );
                
                if (this->useSrcRect) {
                    Tex3DS_SubTexture srcSubTex;
                    srcSubTex.width = (u16)this->srcWidth;
                    srcSubTex.height = (u16)this->srcHeight;
                    Tex3DS_SubTexture* orig = this->image.subtex;
                    float uScale = (orig->right - orig->left) / orig->width;
                    float vScale = (orig->bottom - orig->top) / orig->height;
                    srcSubTex.left = orig->left + this->srcX * uScale;
                    srcSubTex.right = orig->left + (this->srcX + this->srcWidth) * uScale;
                    srcSubTex.top = orig->top + this->srcY * vScale;
                    srcSubTex.bottom = orig->top + (this->srcY + this->srcHeight) * vScale;
                    
                    C2D_Image drawImg = this->image;
                    drawImg.subtex = &srcSubTex;
                    C2D_DrawImageAt(drawImg, 0, 0, 0, &tint, 1, 1);
                } else {
                    C2D_DrawImageAt(this->image, 0, 0, 0, &tint, 1, 1);
                }
            }
            C2D_ViewRestore(&matrix);
        ');
        return true;
    }

    override function destroy() {
        untyped __cpp__('if (this->ss) this->ss = nullptr;');
        super.destroy();
    }
}
#end
