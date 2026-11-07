class CitroEmitter extends CitroGroup
{
    public var gravity:Float;
    public var minSpeed:Float;
    public var maxSpeed:Float;
    public var minAngle:Float;
    public var maxAngle:Float;
    public var minLifespan:Float;
    public var maxLifespan:Float;

    public function new(MaxParticles:Int = 50) 
    {
        super(MaxParticles);
        gravity = 0;
        minSpeed = 50;
        maxSpeed = 150;
        minAngle = 0;
        maxAngle = 360;
        minLifespan = 0.5;
        maxLifespan = 1.5;
    }

    public function setGraphic(Graphic:CitroSprite):Void 
    {
        for (member in members) {
            var p:CitroParticle = cast member;
            p.loadGraphicFromSprite(Graphic);
        }
    }

    public function burst(X:Float, Y:Float, Quantity:Int):Void 
    {
        for (i in 0...Quantity) {
            var p:CitroParticle = cast recycle(CitroParticle);
            p.x = X;
            p.y = Y;
            p.age = 0;
            p.exists = true;
            p.lifespan = CitroRandom.float(minLifespan, maxLifespan);
            p.accelerationY = gravity;
            
            var angle = CitroRandom.float(minAngle, maxAngle) * (Math.PI / 180);
            var speed = CitroRandom.float(minSpeed, maxSpeed);
            
            p.velocityX = Math.cos(angle) * speed;
            p.velocityY = Math.sin(angle) * speed;
            p.scale.x = 1.0;
            p.scale.y = 1.0;
            p.scaleRate = -1.0;
            p.alpha = 1.0;
        }
    }
}
