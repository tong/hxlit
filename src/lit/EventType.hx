package lit;

import js.html.CustomEvent;
import js.html.EventTarget;
import js.lib.WeakMap;

typedef EventTypeOptions = {
	/** Default `true`. **/
	var ?bubbles:Bool;

	/** Crosses shadow DOM boundaries, default `true`. **/
	var ?composed:Bool;

	/** Default `false`. **/
	var ?cancelable:Bool;
}

/**
	A typed custom event: its name and the type of its `detail`.

	```haxe
	class RequestForm extends LitElement {
		public static final REQUEST = new EventType<Request>("request");
		function submit() REQUEST.dispatch(this, {nick: nick, text: text});
	}

	// listening in a template, `onRequest` receives the typed detail
	html(<summ-request-form @request=${RequestForm.REQUEST.listen(onRequest)}></summ-request-form>)
	```

	Use `EventType<Void>` (or any type with no detail passed) for events without detail,
	listeners then take no arguments.
**/
class EventType<T> {
	public final name:String;

	final bubbles:Bool;
	final composed:Bool;
	final cancelable:Bool;
	final listeners = new WeakMap<CustomEvent->Void>();

	public function new(name:String, ?options:EventTypeOptions) {
		this.name = name;
		bubbles = options?.bubbles ?? true;
		composed = options?.composed ?? true;
		cancelable = options?.cancelable ?? false;
	}

	/**
		Dispatches the event on `target`.
		Returns `false` if the event is cancelable and a listener called `preventDefault()`.
	**/
	public function dispatch(target:EventTarget, ?detail:T):Bool
		return target.dispatchEvent(new CustomEvent(name, {
			detail: detail,
			bubbles: bubbles,
			composed: composed,
			cancelable: cancelable
		}));

	/**
		Creates an event listener for a template binding (`@name=${TYPE.listen(f)}`), calling `f` with the detail.
		The listener is cached per `f`, so binding a method keeps the same listener across renders.
	**/
	overload public extern inline function listen(f:T->Void):CustomEvent->Void
		return wrap(f, true);

	/** Creates an event listener for a template binding, calling `f` without arguments. **/
	overload public extern inline function listen(f:() -> Void):CustomEvent->Void
		return wrap(f, false);

	/** Adds a listener for the detail to `target`, returns a function removing it. **/
	overload public extern inline function on(target:EventTarget, f:T->Void):() -> Void
		return add(target, wrap(f, true));

	/** Adds a listener to `target`, returns a function removing it. **/
	overload public extern inline function on(target:EventTarget, f:() -> Void):() -> Void
		return add(target, wrap(f, false));

	public function toString():String
		return name;

	function add(target:EventTarget, listener:CustomEvent->Void):() -> Void {
		target.addEventListener(name, listener);
		return () -> target.removeEventListener(name, listener);
	}

	function wrap(f:Dynamic, withDetail:Bool):CustomEvent->Void {
		var listener = listeners.get(f);
		if (listener == null) {
			listener = withDetail ? e -> f(e.detail) : _ -> f();
			listeners.set(f, listener);
		}
		return listener;
	}
}
