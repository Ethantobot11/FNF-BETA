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
')

class CitroSprite extends CitroObject {
    
    public var srcX:Float = 0;
    public var srcY:Float = 0;
    public var srcWidth:Float = 0;
    public var srcHeight:Float = 0;
    public var useSrcRect:Bool = false;

    public function new(x:Float = 0, y:Float = 0) {
        super();
        this.x = x;
        this.y = y;
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

    public function loadGraphic(file:String):Bool {
        if (CitroG.caches.cache.exists(file)) {
            untyped __cpp__('this->ss = (C2D_SpriteSheet){0}', CitroG.caches.get(file));
        }

        untyped __cpp__('
            if (!this->ss) {
                this->ss = C2D_SpriteSheetLoad(file.c_str());
                if (!this->ss) return false;
            }
            this->image = C2D_SpriteSheetGetImage(this->ss, 0);
            width = this->image.subtex->width;
            height = this->image.subtex->height;
        ');

        CitroG.caches.set(file, untyped __cpp__('this->ss'));
        return true;
    }

    override function update():Bool {

        if (!visible || alpha <= 0) return false;
        
        untyped __cpp__('
            Float sw = this->scale->x, sh = this->scale->y;

            C3D_Mtx matrix;
            Mtx_Diagonal(&matrix, 1.0f, 1.0f, 1.0f, 1.0f);

            C2D_ViewSave(&matrix);
            C2D_ViewTranslate(this->x, this->y);
            C2D_ViewTranslate(this->width * sw / 2.0, this->height * sh / 2.0);
            C2D_ViewRotateDegrees(this->angle);
            C2D_ViewScale(sw, sh);
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
        untyped __cpp__('
            if (this->ss) {
                this->ss = nullptr;
            }
        ');
        super.destroy();
    }
}
#end
