package lit;

/**
	An object that hooks into a host's reactive update lifecycle.

	Implement any of the optional methods `hostConnected`, `hostDisconnected`, `hostUpdate` and `hostUpdated`
	(not declared here, haxe has no notion of optional interface methods).
	Implementing classes are kept from dead code elimination since the methods are only called by lit.

	```haxe
	class MyController implements ReactiveController {
		public function new(host:ReactiveControllerHost) host.addController(this);
		function hostConnected() trace("connected");
	}
	```

	@see https://lit.dev/docs/composition/controllers/
**/
@:keepSub
extern interface ReactiveController {}

/**
	An object that can host reactive controllers.
**/
extern interface ReactiveControllerHost {
	var updateComplete(default, never):js.lib.Promise<Bool>;
	function addController(controller:ReactiveController):Void;
	function removeController(controller:ReactiveController):Void;
	function requestUpdate():Void;
}
