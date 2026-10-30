package lit;

import haxe.DynamicAccess;
import haxe.extern.Rest;
import js.html.Element;
import js.html.TemplateElement;
import lit.directive.DirectiveResult;

/**
	Built-in lit directives and helpers.

	```haxe
	import lit.Directives.*;
	```

	Each function maps to its own `lit/directives/*.js` module, only used ones end up in the output.

	@see https://lit.dev/docs/templates/directives/
**/
class Directives {
	/** Renders values from an async iterable, appending each new value after the previous. **/
	public static inline function asyncAppend<T>(value:AsyncIterable, ?mapper:ItemFn<T>):DirectiveResult
		return mapper == null ? AsyncAppendModule.asyncAppend(value) : AsyncAppendModule.asyncAppend(value, mapper);

	/** Renders values from an async iterable, replacing the previous value with the new value. **/
	public static inline function asyncReplace<T>(value:AsyncIterable, ?mapper:ItemFn<T>):DirectiveResult
		return mapper == null ? AsyncReplaceModule.asyncReplace(value) : AsyncReplaceModule.asyncReplace(value, mapper);

	/** Caches rendered DOM when changing between templates. **/
	public static inline function cache(value:Any):DirectiveResult
		return CacheModule.cache(value);

	/** Chooses and evaluates a template function from a list of `[value, () -> template]` cases. **/
	overload public static extern inline function choose<T, V>(value:T, cases:Array<Array<Dynamic>>):Null<V>
		return ChooseModule.choose(value, cases);

	overload public static extern inline function choose<T, V>(value:T, cases:Array<Array<Dynamic>>, defaultCase:() -> V):Null<V>
		return ChooseModule.choose(value, cases, defaultCase);

	/** Applies CSS classes, where `classInfo` keys are class names and the values determine whether they are applied. **/
	public static inline function classMap(classInfo:ClassInfo):DirectiveResult
		return ClassMapModule.classMap(classInfo);

	/** Prevents re-render of a template function until a single value or an array of values changes. **/
	public static inline function guard<T>(value:Any, f:() -> T):DirectiveResult
		return GuardModule.guard(value, f);

	/** For attribute parts, sets the attribute if the value is defined and removes it if `null`. **/
	public static inline function ifDefined<T>(value:Null<T>):Renderable
		return IfDefinedModule.ifDefined(value);

	/** Returns an iterable containing the values in `items` interleaved with the `joiner` value (or `joiner(index)` if a function). **/
	public static inline function join<J>(items:JsIterable, joiner:J):JsIterable
		return JoinModule.join(items, joiner);

	/** Associates a renderable value with a unique key, forcing a full re-render when the key changes. **/
	public static inline function keyed<T>(key:Any, value:T):DirectiveResult
		return KeyedModule.keyed(key, value);

	/** Checks binding values against live DOM values, instead of previously bound values. **/
	public static inline function live<T>(value:T):DirectiveResult
		return LiveModule.live(value);

	/** Returns an iterable containing the result of calling `f(value, index)` on each value in `items`. **/
	public static inline function map<T>(items:Array<T>, f:ItemFn<T>):JsIterable
		return MapModule.map(items, f);

	/** Returns an iterable of integers from `0` to `end` (exclusive). **/
	overload public static extern inline function range(end:Int):JsIterable
		return RangeModule.range(end);

	/** Returns an iterable of integers from `start` to `end` (exclusive) incrementing by `step`. **/
	overload public static extern inline function range(start:Int, end:Int, step:Int = 1):JsIterable
		return RangeModule.range(start, end, step);

	/** Creates a new `Ref` object, which is a container for a reference to an element. **/
	public static inline function createRef<T:Element>():Ref<T>
		return RefModule.createRef();

	/** Sets the value of a `Ref` object or calls a ref callback with the element it's bound to. **/
	overload public static extern inline function ref<T:Element>(ref:Ref<T>):DirectiveResult
		return RefModule.ref(ref);

	overload public static extern inline function ref<T:Element>(callback:(el:Null<T>) -> Void):DirectiveResult
		return RefModule.ref(callback);

	/** Repeats a series of values generated from `template`, efficiently updating them in place. **/
	overload public static extern inline function repeat<T>(items:Array<T>, template:ItemFn<T>):DirectiveResult
		return RepeatModule.repeat(items, template);

	/** Repeats a series of values generated from `template`, keyed by `keyFn`. **/
	overload public static extern inline function repeat<T>(items:Array<T>, keyFn:ItemFn<T>, template:ItemFn<T>):DirectiveResult
		return RepeatModule.repeat(items, keyFn, template);

	/** Applies CSS properties to an element (keys in camelCase or dash-case `--custom-properties`). **/
	public static inline function styleMap(styleInfo:StyleInfo):DirectiveResult
		return StyleMapModule.styleMap(styleInfo);

	/** Renders the content of a template element as HTML. **/
	public static inline function templateContent(template:TemplateElement):DirectiveResult
		return TemplateContentModule.templateContent(template);

	/** Renders the string as HTML, rather than text. Only use with trusted input. **/
	public static inline function unsafeHTML(value:Null<String>):DirectiveResult
		return UnsafeHTMLModule.unsafeHTML(value);

	/** Renders the string as SVG, rather than text. Only use with trusted input. **/
	public static inline function unsafeSVG(value:Null<String>):DirectiveResult
		return UnsafeSVGModule.unsafeSVG(value);

	/** Renders the string as MathML, rather than text. Only use with trusted input. **/
	public static inline function unsafeMathML(value:Null<String>):DirectiveResult
		return UnsafeMathMLModule.unsafeMathML(value);

	/** Renders one of a series of values, including promises, in priority order (first argument has highest priority). **/
	public static inline function until(values:Rest<Any>):DirectiveResult
		return UntilModule.until(...values);

	/** When `condition` is true, returns the result of calling `trueCase()`, else returns the result of `falseCase()` if given. **/
	overload public static extern inline function when<T>(condition:Bool, trueCase:() -> T):Null<T>
		return WhenModule.when(condition, trueCase);

	overload public static extern inline function when<T>(condition:Bool, trueCase:() -> T, falseCase:() -> T):T
		return WhenModule.when(condition, trueCase, falseCase);
}

/**
	Callback taking an item and optionally its index, `item -> ...` or `(item, index) -> ...`.
**/
abstract ItemFn<T>(Dynamic) from T->Any from (T, Int)->Any {}

/** Keys are CSS class names, values determine whether the class is applied. **/
typedef ClassInfo = DynamicAccess<Bool>;

/** Keys are CSS property names, values are strings, numbers or `null` (removes the property). **/
typedef StyleInfo = DynamicAccess<Any>;

/** A JS async iterable. **/
typedef AsyncIterable = Dynamic;

/** A JS iterable, renderable by lit. **/
typedef JsIterable = Renderable;

@:noCompletion @:js.import(@star "lit/directives/async-append.js")
extern class AsyncAppendModule {
	static function asyncAppend(value:AsyncIterable, ?mapper:Dynamic):DirectiveResult;
}

@:noCompletion @:js.import(@star "lit/directives/async-replace.js")
extern class AsyncReplaceModule {
	static function asyncReplace(value:AsyncIterable, ?mapper:Dynamic):DirectiveResult;
}

@:noCompletion @:js.import(@star "lit/directives/cache.js")
extern class CacheModule {
	static function cache(value:Any):DirectiveResult;
}

@:noCompletion @:js.import(@star "lit/directives/choose.js")
extern class ChooseModule {
	static function choose(value:Any, cases:Array<Array<Dynamic>>, ?defaultCase:Dynamic):Dynamic;
}

@:noCompletion @:js.import(@star "lit/directives/class-map.js")
extern class ClassMapModule {
	static function classMap(classInfo:ClassInfo):DirectiveResult;
}

@:noCompletion @:js.import(@star "lit/directives/guard.js")
extern class GuardModule {
	static function guard(value:Any, f:Dynamic):DirectiveResult;
}

@:noCompletion @:js.import(@star "lit/directives/if-defined.js")
extern class IfDefinedModule {
	static function ifDefined(value:Any):Renderable;
}

@:noCompletion @:js.import(@star "lit/directives/join.js")
extern class JoinModule {
	static function join(items:Dynamic, joiner:Dynamic):JsIterable;
}

@:noCompletion @:js.import(@star "lit/directives/keyed.js")
extern class KeyedModule {
	static function keyed(key:Any, value:Any):DirectiveResult;
}

@:noCompletion @:js.import(@star "lit/directives/live.js")
extern class LiveModule {
	static function live(value:Any):DirectiveResult;
}

@:noCompletion @:js.import(@star "lit/directives/map.js")
extern class MapModule {
	static function map(items:Dynamic, f:Dynamic):JsIterable;
}

@:noCompletion @:js.import(@star "lit/directives/range.js")
extern class RangeModule {
	@:overload(function(start:Int, end:Int, step:Int):JsIterable {})
	static function range(end:Int):JsIterable;
}

@:noCompletion @:js.import(@star "lit/directives/ref.js")
extern class RefModule {
	static function createRef():Dynamic;
	static function ref(ref:Dynamic):DirectiveResult;
}

@:noCompletion @:js.import(@star "lit/directives/repeat.js")
extern class RepeatModule {
	@:overload(function(items:Dynamic, keyFn:Dynamic, template:Dynamic):DirectiveResult {})
	static function repeat(items:Dynamic, template:Dynamic):DirectiveResult;
}

@:noCompletion @:js.import(@star "lit/directives/style-map.js")
extern class StyleMapModule {
	static function styleMap(styleInfo:StyleInfo):DirectiveResult;
}

@:noCompletion @:js.import(@star "lit/directives/template-content.js")
extern class TemplateContentModule {
	static function templateContent(template:TemplateElement):DirectiveResult;
}

@:noCompletion @:js.import(@star "lit/directives/unsafe-html.js")
extern class UnsafeHTMLModule {
	static function unsafeHTML(value:Null<String>):DirectiveResult;
}

@:noCompletion @:js.import(@star "lit/directives/unsafe-svg.js")
extern class UnsafeSVGModule {
	static function unsafeSVG(value:Null<String>):DirectiveResult;
}

@:noCompletion @:js.import(@star "lit/directives/unsafe-mathml.js")
extern class UnsafeMathMLModule {
	static function unsafeMathML(value:Null<String>):DirectiveResult;
}

@:noCompletion @:js.import(@star "lit/directives/until.js")
extern class UntilModule {
	static function until(values:Rest<Any>):DirectiveResult;
}

@:noCompletion @:js.import(@star "lit/directives/when.js")
extern class WhenModule {
	@:overload(function(condition:Bool, trueCase:Dynamic, falseCase:Dynamic):Dynamic {})
	static function when(condition:Bool, trueCase:Dynamic):Dynamic;
}
