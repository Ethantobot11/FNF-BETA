package citro.object;

import citro.CitroG;
import citro.object.CitroGroup;
import citro.object.CitroSprite;
import citro.math.CitroRandom;

class CitroParticle extends CitroSprite
{
    public var lifespan:Float;
    public var age:Float;
    public var velocityX:Float;
    public var velocityY:Float;
    public var accelerationY:Float;
    public var scaleRate:Float;

    public function new() 
    {
        super(0, 0);
        lifespan = 1.0;
        age = 0;
        velocityX = 0;
        velocityY = 0;
        accelerationY = 0;
        scaleRate = 0;
        exists = false;
    }

    override public function update():Bool 
    {
        if (!exists) return false;

        age += CitroG.deltaTime / 1000.0;
        if (age >= lifespan) {
            exists = false;
            return false;
        }

        velocityY += accelerationY * (CitroG.deltaTime / 1000.0);
        x += velocityX * (CitroG.deltaTime / 1000.0);
        y += velocityY * (CitroG.deltaTime / 1000.0);

        if (scaleRate != 0) {
            scale.x += scaleRate * (CitroG.deltaTime / 1000.0);
            scale.y += scaleRate * (CitroG.deltaTime / 1000.0);
        }

        var lifePercent = 1.0 - (age / lifespan);
        alpha = lifePercent;

        return super.update();
    }
}
