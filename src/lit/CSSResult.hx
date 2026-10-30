package lit;

import js.html.CSSStyleSheet;

/**
	Result of a `css` template or `unsafeCSS`.
**/
@:jsRequire("lit", "CSSResult")
extern class CSSResult {
	final cssText:String;
	final styleSheet:Null<CSSStyleSheet>;
	function toString():String;
}

/**
	A single style, or a (nested) array of styles.
**/
abstract CSSResultGroup(Dynamic) from CSSResult from CSSStyleSheet from Array<CSSResult> from Array<CSSStyleSheet> from Array<CSSResultGroup> {}
