package lit.directive;

import lit.directive.Part;

/**
	Base class for creating custom directives.

	Subclasses implement a `render(...)` method (with any signature) and optionally override `update`.
	Use `Directive.create` to turn the class into a directive function.

	```haxe
	class HelloDirective extends Directive {
		public function new(partInfo:PartInfo) super(partInfo);
		function render(name:String) return 'Hello $name';
	}
	final hello:(name:String) -> DirectiveResult = Directive.create(HelloDirective);
	```

	@see https://lit.dev/docs/templates/custom-directives/
**/
@:jsRequire("lit/directive.js", "Directive")
@:keepSub // `render` is only called by lit
extern class Directive {
	function new(partInfo:PartInfo);

	/** Called on every render with the part and the arguments passed to the directive function. **/
	function update(part:Part, props:Array<Any>):Any;

	/** Creates a directive function from a `Directive` class (lit's `directive`). **/
	static inline function create<T:haxe.Constraints.Function>(c:Class<Directive>):T
		return DirectiveModule.directive(c);
}

@:noCompletion @:jsRequire("lit/directive.js")
extern class DirectiveModule {
	static function directive(c:Class<Directive>):Dynamic;
}
