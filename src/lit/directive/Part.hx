package lit.directive;

import js.html.Element;
import js.html.Node;
import lit.RenderOptions;

/**
	Information about the part a directive is bound to, passed to the directive constructor.
**/
typedef PartInfo = {
	final type:PartType;

	/** Attribute name (attribute, property, boolean attribute and event parts). **/
	final ?name:String;

	/** Element tag name (attribute, property, boolean attribute and event parts). **/
	final ?tagName:String;

	/** Static strings of an interpolated attribute value. **/
	final ?strings:haxe.ds.ReadOnlyArray<String>;
}

/**
	A part of a template instance, passed to `Directive.update`.
**/
typedef Part = {
	final type:PartType;
	final ?options:RenderOptions;

	/** Element of attribute, property, boolean attribute, event and element parts. **/
	final ?element:Element;

	/** Name of attribute, property, boolean attribute and event parts. **/
	final ?name:String;

	/** Parent node of child parts. **/
	final ?parentNode:Node;

	/** Start node of child parts. **/
	final ?startNode:Null<Node>;

	/** End node of child parts. **/
	final ?endNode:Null<Node>;
}
