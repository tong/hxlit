package lit;

/**
	Anything lit can render in a child position: templates, directive results, strings, numbers, nodes,
	arrays of these, `nothing` and `noChange`.

	Returned by `html`, `svg`, `mathml` and all directives, so they unify in conditionals and switches:

	```haxe
	cond ? html(<b>yes</b>) : nothing
	```
**/
abstract Renderable(Dynamic) from String from Int from Float from Bool from js.html.Node {
	@:from static inline function fromArray<T>(a:Array<T>):Renderable
		return cast a;
}
