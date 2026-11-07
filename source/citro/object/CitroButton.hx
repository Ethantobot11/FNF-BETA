package citro.object;

import citro.CitroG;
import citro.backend.CitroColor;
import haxe3ds.services.HID;

class CitroButton extends CitroSprite 
{
    public var label:CitroText;
    public var onClicked:Void->Void;
    
    private var isHovered:Bool = false;
    private var baseColor:CitroColor;
    private var hoverColor:CitroColor;

    public function new(X:Float, Y:Float, Width:Float, Height:Float, LabelText:String, ?OnClick:Void->Void) 
    {
        super(X, Y);
        makeGraphic(Width, Height, 0xFF444444);
        baseColor = 0xFF444444;
        hoverColor = 0xFFFFD700;
        label = new CitroText(X + (Width / 2), Y + (Height / 2), LabelText);
        label.alignment = CENTER;
        label.bottom = this.bottom;
        
        onClicked = OnClick;
    }

    override public function update():Bool 
    {
        label.x = this.x + (width / 2);
        label.y = this.y + (height / 2);
        label.bottom = this.bottom;
        
        if (!label.isDestroyed) {
            label.update();
        }

        if (bottom && HID.keyHeld(HIDKey.TOUCH)) {
            var touch = HID.touch;
            isHovered = (touch.px >= x && touch.px <= x + width && 
                        touch.py >= y && touch.py <= y + height);
        } else {
            isHovered = false;
        }
        
        if (isHovered && (HID.keyPressed(HIDKey.A) || HID.keyPressed(HIDKey.TOUCH))) {
            if (onClicked != null) onClicked();
        }
        
        if (isHovered) {
            color = hoverColor;
        } else {
            color = baseColor;
        }
        
        return super.update();
    }

    public function setHovered(Hovered:Bool):Void 
    {
        isHovered = Hovered;
        color = isHovered ? hoverColor : baseColor;
    }
}