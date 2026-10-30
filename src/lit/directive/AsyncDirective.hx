package lit.directive;

/**
	A directive that can update its value asynchronously, and is notified when it is disconnected/reconnected.

	@see https://lit.dev/docs/templates/custom-directives/#async-directives
**/
@:jsRequire("lit/async-directive.js", "AsyncDirective")
extern class AsyncDirective extends Directive {
	/** The connection state of the directive. **/
	final isConnected:Bool;

	/** Sets the value of the directive's part outside the normal update/render lifecycle. **/
	function setValue(value:Any):Void;

	/** Called when the directive is disconnected from the DOM. **/
	private function disconnected():Void;

	/** Called when the directive is reconnected to the DOM after a previous disconnection. **/
	private function reconnected():Void;
}
