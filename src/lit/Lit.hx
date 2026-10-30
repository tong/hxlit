package lit;

#if macro
import haxe.macro.Expr;
import lit.macro.Template;
#else
import js.html.DocumentFragment;
import js.html.Element;
import js.html.ShadowRoot;
import haxe.extern.EitherType;
import lit.CSSResult;
#end

/**
	Template tags and top-level functions of lit.

	```haxe
	import lit.Lit.*;
	```

	The template macros `html`, `svg`, `mathml` and `css` take a string literal.
	Single quoted strings are interpolated, each interpolation becomes a template expression:

	```haxe
	html('<button @click=${onClick} ?disabled=${!enabled}>${label}</button>')
	```

	Inline markup is interpolated the same way:

	```haxe
	html(<button @click=${onClick}>${label}</button>)
	```

	They compile to native JS tagged template literals, so lit's template caching works as usual.
**/
class Lit {
	/** Interprets a template literal as an HTML template. **/
	public static macro function html(template:ExprOf<String>):ExprOf<Renderable>
		return Template.build(macro lit.Lit.LitModule.html, template, macro :lit.Renderable);

	/** Interprets a template literal as an SVG fragment. **/
	public static macro function svg(template:ExprOf<String>):ExprOf<Renderable>
		return Template.build(macro lit.Lit.LitModule.svg, template, macro :lit.Renderable);

	/** Interprets a template literal as MathML fragment. **/
	public static macro function mathml(template:ExprOf<String>):ExprOf<Renderable>
		return Template.build(macro lit.Lit.LitModule.mathml, template, macro :lit.Renderable);

	/**
		Template tag for styles.
		Interpolated values must be `CSSResult` or numbers, use `unsafeCSS` for others.
	**/
	public static macro function css(template:ExprOf<String>):ExprOf<CSSResult>
		return Template.build(macro lit.Lit.LitModule.css, template, macro :lit.CSSResult);

	#if !macro
	/** Sentinel value that signals a child part to fully clear its content. **/
	public static var nothing(get, never):Renderable;

	static inline function get_nothing():Renderable
		return LitModule.nothing;

	/** Sentinel value that signals that a value was handled by a directive and should not be written. **/
	public static var noChange(get, never):Renderable;

	static inline function get_noChange():Renderable
		return LitModule.noChange;

	/** `true` when running in a server environment. **/
	public static var isServer(get, never):Bool;

	static inline function get_isServer():Bool
		return LitModule.isServer;

	/** Renders a value, usually a template, to a container. **/
	public static inline function render(value:Renderable, container:EitherType<Element, DocumentFragment>, ?options:RenderOptions):RootPart
		return LitModule.render(value, container, options);

	/** Wraps a value for interpolation in a `css` template, only use with trusted input. **/
	public static inline function unsafeCSS(value:Any):CSSResult
		return LitModule.unsafeCSS(value);

	/** Applies styles to a shadow root. **/
	public static inline function adoptStyles(renderRoot:ShadowRoot, styles:Array<CSSResultGroup>):Void
		LitModule.adoptStyles(renderRoot, styles);

	/** Change function that returns true if `value` is different from `oldValue` (default `hasChanged`). **/
	public static inline function notEqual(value:Any, old:Any):Bool
		return LitModule.notEqual(value, old);
	#end
}

#if !macro
/**
	A child part returned by `render`.
**/
extern class RootPart {
	/** Sets the connection state for `AsyncDirective`s contained within this root part. **/
	function setConnected(isConnected:Bool):Void;
}

@:noCompletion
@:js.import(@star "lit")
extern class LitModule {
	static final nothing:Renderable;
	static final noChange:Renderable;
	static final isServer:Bool;
	static final supportsAdoptingStyleSheets:Bool;
	static final defaultConverter:PropertyDeclaration.ComplexAttributeConverter;
	static function html(strings:Array<String>, values:haxe.extern.Rest<Any>):Renderable;
	static function svg(strings:Array<String>, values:haxe.extern.Rest<Any>):Renderable;
	static function mathml(strings:Array<String>, values:haxe.extern.Rest<Any>):Renderable;
	static function css(strings:Array<String>, values:haxe.extern.Rest<Any>):CSSResult;
	static function render(value:Renderable, container:EitherType<Element, DocumentFragment>, ?options:RenderOptions):RootPart;
	static function unsafeCSS(value:Any):CSSResult;
	static function adoptStyles(renderRoot:ShadowRoot, styles:Array<CSSResultGroup>):Void;
	static function notEqual(value:Any, old:Any):Bool;
}
#end
