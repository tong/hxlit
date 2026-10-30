package lit;

/**
	Base element class for lit components, rendering templates via `render()`.

	```haxe
	import lit.Lit.*;

	@:customElement("my-greeter")
	class Greeter extends lit.LitElement {
		static var styles = css('p { color: blue; }');
		@:property var name = "World";
		override function render() return html('<p>Hello ${name}!</p>');
	}
	```

	Subclasses are processed by `lit.macro.Element.build`, see there for supported metadata.

	@see https://lit.dev/docs/api/LitElement/
**/
@:js.import("lit", "LitElement")
extern class LitElement extends ReactiveElement {
	final renderOptions:RenderOptions;

	function new();

	/** Returns what to render, usually an `html` template. **/
	private function render():Renderable;
}
