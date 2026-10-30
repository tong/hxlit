package lit;

typedef RenderOptions = {
	/** Object used as `this` for event listeners. **/
	var ?host:{};

	/** A node in the render container before which to render. **/
	var ?renderBefore:js.html.Node;

	/** Node used for cloning the template (`importNode` is called on it). **/
	var ?creationScope:{function importNode(node:js.html.Node, ?deep:Bool):js.html.Node;};

	/** Initial connected state for the top-level part being rendered. **/
	var ?isConnected:Bool;
}
