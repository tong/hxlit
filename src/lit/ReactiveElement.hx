package lit;

import js.html.CSSStyleSheet;
import js.html.ShadowRootInit;
import js.lib.Map;
import js.lib.Promise;
import lit.CSSResult;
import lit.PropertyDeclaration;
import lit.ReactiveController;

/**
	Base element class which manages element properties and attributes.
	When properties change, the `update` method is asynchronously called.

	Subclasses are processed by `lit.macro.Element.build`, see there for supported metadata.

	@see https://lit.dev/docs/api/ReactiveElement/
**/
@:js.import("lit", "ReactiveElement")
@:autoBuild(lit.macro.Element.build())
extern class ReactiveElement extends js.html.Element implements ReactiveControllerHost {
	static var elementProperties(default, never):Map<String, PropertyDeclaration>;
	static var elementStyles(default, never):Array<EitherType<CSSResult, CSSStyleSheet>>;
	static var observedAttributes(default, never):Array<String>;
	static var shadowRootOptions:ShadowRootInit;
	static var enabledWarnings:Array<WarningKind>;

	static function addInitializer(initializer:ReactiveElement->Void):Void;
	static function createProperty(name:String, ?options:PropertyDeclaration):Void;
	static function getPropertyOptions(name:String):PropertyDeclaration;
	static function enableWarning(warningKind:WarningKind):Void;
	static function disableWarning(warningKind:WarningKind):Void;
	private static function finalize():Void;
	private static function finalizeStyles(?styles:CSSResultGroup):Array<EitherType<CSSResult, CSSStyleSheet>>;

	/** Node or ShadowRoot into which element DOM should be rendered. **/
	final renderRoot:RenderRoot;

	/** True if there is a pending update. **/
	var isUpdatePending:Bool;

	/** Is set to `true` after the first update. **/
	var hasUpdated:Bool;

	/** Promise that resolves when the element has finished updating (`false` if another update was triggered). **/
	var updateComplete(default, never):Promise<Bool>;

	function new();

	function addController(controller:ReactiveController):Void;
	function removeController(controller:ReactiveController):Void;

	function connectedCallback():Void;
	function disconnectedCallback():Void;
	function attributeChangedCallback(name:String, old:Null<String>, value:Null<String>):Void;

	/** Requests an update which is processed asynchronously. **/
	@:overload(function():Void {})
	function requestUpdate(name:String, ?oldValue:Any, ?options:PropertyDeclaration):Void;

	private function createRenderRoot():RenderRoot;
	private function enableUpdating(requestedUpdate:Bool):Void;
	private function scheduleUpdate():Null<Promise<Any>>;
	private function performUpdate():Void;
	private function getUpdateComplete():Promise<Bool>;
	private function shouldUpdate(changedProperties:PropertyValues):Bool;
	private function willUpdate(changedProperties:PropertyValues):Void;
	private function update(changedProperties:PropertyValues):Void;
	private function updated(changedProperties:PropertyValues):Void;
	private function firstUpdated(changedProperties:PropertyValues):Void;
}

enum abstract WarningKind(String) to String {
	var ChangeInUpdate = "change-in-update";
	var Migration = "migration";
	var AsyncPerformUpdate = "async-perform-update";
}

private typedef EitherType<A, B> = haxe.extern.EitherType<A, B>;
