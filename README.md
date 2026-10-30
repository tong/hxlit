# HXLit

Haxe externs for [lit](https://lit.dev/), a library for building fast, lightweight web components.

The library version follows the lit version it was written for.

## Install

```sh
haxelib dev lit path/to/hxlit
npm install lit
```

Requires Haxe 5. Custom elements must be real ES6 classes, so `-lib lit` adds `-D js-es=6` through `extraParams.hxml`. If you add `src/` to the classpath directly instead, set `-D js-es=6` yourself; the build macro raises an error without it.

The output uses `require()`, so bundle it with [esbuild](https://esbuild.github.io/), vite, or similar:

```hxml
-lib lit
-main Main
-js bin/main.js
```

```sh
esbuild bin/main.js --bundle --format=esm --outfile=bin/bundle.js
```

## Usage

```haxe
import lit.Lit.*;
import lit.LitElement;

@:customElement("my-counter")
class Counter extends LitElement {
	static var styles = css('button { color: blue; }');

	@:property var count = 0;
	@:property({reflect: true}) var label = "Count";

	override function render()
		return html('<button @click=${() -> count++}>${label}: ${count}</button>');
}
```

```html
<my-counter count="5"></my-counter>
```

### Templates

`html`, `svg`, `mathml` and `css` are macros taking a string literal. Each interpolation in a single quoted string becomes a template expression:

```haxe
html('<input .value=${text} ?disabled=${!enabled} @input=${onInput}>')
```

They compile to native JS tagged template literals, so lit's template caching works as usual:

```js
lit_LitModule.html`<input .value=${this.text} ?disabled=${!this.enabled} @input=${$bind(this,this.onInput)}>`
```

Double quoted strings are not interpolated, the same as in Haxe.

Inline markup works the same way, as long as it has a single root element:

```haxe
html(<button class=${cls} @click=${onClick}>Hello $name</button>)
```

Templates, directives, `nothing` and `noChange` are all typed `lit.Renderable`. Strings, numbers, nodes and arrays convert to it, so conditionals and switches unify:

```haxe
cond ? html(<b>yes</b>) : nothing
```

Custom element tags used in templates are checked after typing. A tag that no compiled class with `@:customElement` defines produces a warning. Usually this means a missing import: a class referenced only by its tag name is never compiled. To declare third-party elements, add an extern class with `@:customElement("their-tag")`. Its `require()` is emitted only if the class is referenced, so mention it once (e.g. `SlButton;`) to load the component. To disable the check, use `-D lit-no-tag-check`.

### Elements

Subclasses of `LitElement` (and `ReactiveElement`) are processed by a build macro:

| Metadata | |
|---|---|
| `@:customElement("tag-name")` | Registers the class with `customElements.define` |
| `@:property` | Reactive property. `type` is inferred: `Int`/`Float` → `Number`, `Bool` → `Boolean`, `String`, `Array`, else `Object` |
| `@:property({reflect: true, attribute: "my-attr"})` | Reactive property with [options](https://lit.dev/docs/components/properties/#property-options). `type: Boolean` etc. works as in JS, Haxe names like `Bool` and `Int` are accepted too |
| `@:state` | Internal reactive state |
| `@:query("#selector")` | Getter returning `renderRoot.querySelector(selector)` |
| `@:queryAll(".selector")` | Getter returning `renderRoot.querySelectorAll(selector)` |

The macro also:

- moves field initializers into the constructor after `super()`. Haxe doesn't allow initializers in ES6 classes that extend externs. Because of this, the macro must know each initialized field's type. Fields with generic initializers such as `final input:Ref<InputElement> = createRef()` need a type hint.
- keeps lifecycle overrides (`render`, `updated`, …) and the `styles` static from dead code elimination.

Reactive property names must not clash with existing `HTMLElement` fields such as `title`, `hidden` or `id`.

### Events

`lit.EventType<T>` names a custom event and the type of its `detail`:

```haxe
class RequestForm extends LitElement {
	public static final REQUEST = new EventType<Request>("request");

	function submit()
		REQUEST.dispatch(this, {nick: nick, text: text}); // payload is type checked
}

class App extends LitElement {
	function onRequest(req:Request) { ... }

	override function render()
		return html(<summ-request-form @request=${RequestForm.REQUEST.listen(onRequest)}></summ-request-form>);
}
```

- `listen(f)` creates the listener for a template binding. `f` receives the typed detail, or takes no arguments for an `EventType<Void>`. The listener is cached per `f`, so binding a method gives Lit the same listener on every render.
- `on(target, f)` adds a listener in code and returns a function that removes it.
- Events bubble and cross shadow DOM boundaries by default. Change this with `new EventType("name", {bubbles: false, composed: false, cancelable: true})`.
- The template macro checks `@name=${TYPE.listen(...)}` against the `EventType`'s name, so `@sent=${Chat.SEND.listen(f)}` is a compile error.

To get the raw event (for `preventDefault()` or `target`), bind a plain listener: `@request=${(e:js.html.CustomEvent) -> ...}`.

### Directives

```haxe
import lit.Directives.*;

html('<ul>${repeat(items, item -> item.id, item -> html('<li class=${classMap({done: item.done})}>${item.text}</li>'))}</ul>');
```

`createRef()` returns a `lit.Ref<T>`, which needs its own `import lit.Ref`.

All built-in directives are available: `asyncAppend`, `asyncReplace`, `cache`, `choose`, `classMap`, `guard`, `ifDefined`, `join`, `keyed`, `live`, `map`, `range`, `createRef`/`ref`, `repeat`, `styleMap`, `templateContent`, `unsafeHTML`, `unsafeSVG`, `unsafeMathML`, `until`, `when`.

Custom directives extend `lit.directive.Directive` (or `AsyncDirective`):

```haxe
class Upper extends Directive {
	public function new(partInfo:PartInfo) super(partInfo);
	function render(s:String) return s.toUpperCase();
}

final upper:(s:String) -> DirectiveResult = Directive.create(Upper);
```

### Reactive controllers

```haxe
class ClockController implements ReactiveController {
	final host:ReactiveControllerHost;

	public function new(host:ReactiveControllerHost) {
		this.host = host;
		host.addController(this);
	}

	function hostConnected() { ... }
	function hostDisconnected() { ... }
}
```

The hook methods are optional. Classes implementing `ReactiveController` are kept from dead code elimination.

## Demo

A mock of a web chat client: a request form, a waiting state, chat with receipts and typing notifications, and calls, all against a fake server. It uses nested components, slots, shared styles, typed custom events, enum state machines and reactive controllers.

```sh
npm install
npm run build:demo
npx esbuild --servedir=demo
```

The demo bundles Lit's development build (`esbuild --conditions=development`), which logs warnings about misuse. Drop the flag for production.

## Test

The tests run in node with [jsdom](https://github.com/jsdom/jsdom) and need [utest](https://github.com/haxe-utest/utest):

```sh
npm install
npm test
```
