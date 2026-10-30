package lit;

/**
	Container for a reference to an element, created by `Directives.createRef` and bound with `Directives.ref`.
**/
typedef Ref<T:js.html.Element> = {
	final value:Null<T>;
}
