package lit;

import js.html.DocumentFragment;
import js.html.Element;
import js.html.Node;
import js.html.NodeList;

/**
	The node a component renders into: its shadow root, or the element itself.
**/
@:forward
abstract RenderRoot(Node) from Element from DocumentFragment to Node {
	public inline function querySelector(selectors:String):Null<Element>
		return (cast this : Element).querySelector(selectors);

	public inline function querySelectorAll(selectors:String):NodeList
		return (cast this : Element).querySelectorAll(selectors);
}
