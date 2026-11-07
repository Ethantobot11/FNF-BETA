package citro.util;

class CitroSignal<T>
{
    private var listeners:Array<T->Void> = [];
    private var pendingRemove:Array<T->Void> = [];
    private var isDispatching:Bool = false;

    public function new() {}

    public function add(listener:T->Void):Void 
    {
        if (listener != null && !has(listener)) {
            listeners.push(listener);
        }
    }

    public function addOnce(listener:T->Void):Void 
    {
        if (listener != null && !has(listener)) {
            var wrapped:T->Void = function(data:T) {
                listener(data);
                remove(wrapped);
            };
            listeners.push(wrapped);
        }
    }

    public function remove(listener:T->Void):Void 
    {
        if (isDispatching) {
            pendingRemove.push(listener);
        } else {
            listeners.remove(listener);
        }
    }

    public function has(listener:T->Void):Bool 
    {
        return listeners.indexOf(listener) != -1;
    }

    public function dispatch(data:T):Void 
    {
        isDispatching = true;
        for (listener in listeners) {
            listener(data);
        }
        isDispatching = false;

        if (pendingRemove.length > 0) {
            for (listener in pendingRemove) {
                listeners.remove(listener);
            }
            pendingRemove = [];
        }
    }

    public function clear():Void 
    {
        listeners = [];
        pendingRemove = [];
    }
}
