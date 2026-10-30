import js.Browser.document;
import js.html.ButtonElement;
import js.html.DivElement;
import js.html.Element;
import lit.Directives.*;
import lit.Lit.*;
import lit.EventType;
import lit.LitElement;
import lit.PropertyValues;
import lit.directive.Directive;
import lit.directive.DirectiveResult;
import lit.directive.Part;
import utest.Assert;
import utest.Async;

class Test {
	static function main() {
		final runner = new utest.Runner();
		runner.addCase(new TestTemplate());
		runner.addCase(new TestElement());
		runner.addCase(new TestDirectives());
		runner.addCase(new TestEvents());
		new utest.ui.text.PrintReport(runner);
		new utest.ui.common.ResultAggregator(runner).onComplete.add(result -> js.Syntax.code("window.onTestsDone({0})", result.stats.isOk));
		runner.run();
	}
}

/** Strips lit's comment markers **/
function text(el:Element):String
	return ~/<!--[^>]*-->/g.replace(el.innerHTML, "");

function shadow(el:Element):String
	return text(cast el.shadowRoot);

function mount<T:Element>(el:T):T {
	document.body.appendChild(el);
	return el;
}

class TestTemplate extends utest.Test {
	function testInterpolation() {
		final div = document.createDivElement();
		final name = "World";
		final n = 3;
		render(html('<p class="${name}">Hello ${name} $n ${n + 1}</p>'), div);
		Assert.equals('<p class="World">Hello World 3 4</p>', text(div));
	}

	function testMarkup() {
		final div = document.createDivElement();
		final name = "World";
		var clicked = false;
		render(html(<p class=${name}>Hello $name <b>${name.length}</b><button @click=${() -> clicked = true}></button></p>), div);
		Assert.equals('<p class="World">Hello World <b>5</b><button></button></p>', text(div));
		div.querySelector("button").click();
		Assert.isTrue(clicked);
	}

	function testDoubleQuotedIsStatic() {
		final div = document.createDivElement();
		render(html("<p>${name}</p>"), div);
		Assert.equals("<p>${name}</p>", text(div));
	}

	function testEscaping() {
		final div = document.createDivElement();
		final v = "x";
		render(html('<p>`a` \\ $$${v} {0} {x} $5</p>'), div);
		Assert.equals("<p>`a` \\ $x {0} {x} $5</p>", text(div));
	}

	function testNestedBracesAndStrings() {
		final div = document.createDivElement();
		final items = ["a", "b"];
		render(html('<ul>${items.map(i -> html('<li>${i + "}"}</li>'))}</ul>'), div);
		Assert.equals("<ul><li>a}</li><li>b}</li></ul>", text(div));
	}

	function testTemplateCaching() {
		final div = document.createDivElement();
		function tpl(v:String)
			return html('<p>${v}</p>');
		render(tpl("a"), div);
		final p = div.querySelector("p");
		render(tpl("b"), div);
		Assert.equals(p, div.querySelector("p"));
		Assert.equals("<p>b</p>", text(div));
		Assert.equals((tpl("x") : Dynamic).strings, (tpl("y") : Dynamic).strings);
	}

	function testRenderableUnifies() {
		final div = document.createDivElement();
		function content(i:Int)
			return switch i {
				case 0: html('<b>template</b>');
				case 1: "text";
				case 2: 42;
				case 3: classMap({a: true});
				case _: nothing;
			}
		final cond = div.childNodes.length == 0;
		final a = cond ? html('<i>yes</i>') : nothing;
		final b = cond ? nothing : html('<i>no</i>');
		final c = cond ? "str" : nothing;
		render(html('${a}${b}${c}${content(0)}${content(1)}${content(2)}${content(4)}${[html('<u></u>'), "x"]}'), div);
		Assert.equals("<i>yes</i>str<b>template</b>text42<u></u>x", text(div));
	}

	function testNothing() {
		final div = document.createDivElement();
		render(html('<p>${nothing}</p>'), div);
		Assert.equals("<p></p>", text(div));
	}

	function testSvg() {
		final div = document.createDivElement();
		final r = 5;
		render(html('<svg>${svg('<circle r=${r}></circle>')}</svg>'), div);
		Assert.equals("circle", div.querySelector("circle").localName);
		Assert.equals("http://www.w3.org/2000/svg", div.querySelector("circle").namespaceURI);
	}

	function testCss() {
		final color = unsafeCSS("red");
		final size = 2;
		final style = css(':host { color: ${color}; margin: ${size}px; }');
		Assert.equals(":host { color: red; margin: 2px; }", style.cssText);
	}

	function testEventBinding() {
		final div = document.createDivElement();
		var clicked = 0;
		render(html('<button @click=${() -> clicked++}></button>'), div);
		div.querySelector("button").click();
		Assert.equals(1, clicked);
	}
}

@:customElement("test-counter")
class Counter extends LitElement {
	static var styles = css('p { color: red; }');

	@:property var count = 0;
	@:property({reflect: true}) var label:String = "n";
	@:property var enabled = true;
	@:property({type: Boolean, attribute: "is-flag"}) public var flag:Dynamic = false;
	@:property({attribute: "data-items"}) var items:Array<String> = [];
	@:state var renders = 0;
	@:query("button") public var button:ButtonElement;
	var plain = "not reactive";

	override function willUpdate(changed:PropertyValues) {
		renders++;
	}

	function increment()
		count++;

	override function render()
		return html('<p>${label}=${count}</p><button @click=${increment} ?disabled=${!enabled}>+</button>${items.join(",")}');
}

@:customElement("test-sub")
class SubCounter extends Counter {
	@:property var step = 10;

	public function new() {
		super();
		step = step * 2;
	}

	override function increment()
		count += step;
}

@:customElement("test-light")
class LightElement extends LitElement {
	override function createRenderRoot()
		return this;

	override function render()
		return html('<span>light</span>');
}

class TestElement extends utest.Test {
	function testRender(async:Async) {
		final el:Counter = mount(cast document.createElement("test-counter"));
		el.updateComplete.then(_ -> {
			Assert.equals('<p>n=0</p><button>+</button>', shadow(el).split('<style>p { color: red; }</style>').join(""));
			// jsdom has no adoptedStyleSheets, lit falls back to style elements
			Assert.equals("p { color: red; }", el.shadowRoot.querySelector("style").textContent);
			async.done();
		});
	}

	function testReactiveProperty(async:Async) {
		final el:Counter = mount(cast document.createElement("test-counter"));
		el.updateComplete.then(_ -> {
			final p = el.shadowRoot.querySelector("p");
			el.button.click();
			Assert.isTrue(el.isUpdatePending);
			return el.updateComplete.then(_ -> {
				Assert.equals("n=1", p.textContent);
				Assert.equals(p, el.shadowRoot.querySelector("p"));
				Assert.equals(2, @:privateAccess el.renders);
				async.done();
			});
		});
	}

	function testAttributeConversion(async:Async) {
		final div = document.createDivElement();
		div.innerHTML = '<test-counter count="5" label="x" data-items=\'["a","b"]\'></test-counter>';
		final el:Counter = cast div.firstChild;
		mount(div);
		el.updateComplete.then(_ -> {
			Assert.equals(5, @:privateAccess el.count);
			Assert.equals("number", js.Syntax.typeof(@:privateAccess el.count));
			Assert.equals("x=5", el.shadowRoot.querySelector("p").textContent);
			Assert.same(["a", "b"], @:privateAccess el.items);
			el.setAttribute("count", "7");
			return el.updateComplete.then(_ -> {
				Assert.equals(7, @:privateAccess el.count);
				async.done();
			});
		});
	}

	function testTypeOption(async:Async) {
		final div = document.createDivElement();
		div.innerHTML = '<test-counter is-flag></test-counter>';
		final el:Counter = cast div.firstChild;
		mount(div);
		el.updateComplete.then(_ -> {
			// `type: Boolean` maps to the JS Boolean converter, despite the Dynamic field type
			Assert.isTrue(el.flag == true);
			async.done();
		});
	}

	function testReflect(async:Async) {
		final el:Counter = mount(cast document.createElement("test-counter"));
		@:privateAccess el.label = "reflected";
		el.updateComplete.then(_ -> {
			Assert.equals("reflected", el.getAttribute("label"));
			Assert.isNull(el.getAttribute("count"));
			async.done();
		});
	}

	function testBooleanAttributeBinding(async:Async) {
		final el:Counter = mount(cast document.createElement("test-counter"));
		@:privateAccess el.enabled = false;
		el.updateComplete.then(_ -> {
			Assert.isTrue(el.button.disabled);
			async.done();
		});
	}

	function testNonReactiveField(async:Async) {
		final el:Counter = mount(cast document.createElement("test-counter"));
		el.updateComplete.then(_ -> {
			Assert.equals("not reactive", @:privateAccess el.plain);
			@:privateAccess el.plain = "changed";
			Assert.isFalse(el.isUpdatePending);
			async.done();
		});
	}

	function testSubclass(async:Async) {
		final el:SubCounter = mount(cast document.createElement("test-sub"));
		Assert.equals(20, @:privateAccess el.step);
		Assert.equals(0, @:privateAccess el.count);
		el.updateComplete.then(_ -> {
			el.button.click();
			return el.updateComplete.then(_ -> {
				Assert.equals("n=20", el.shadowRoot.querySelector("p").textContent);
				async.done();
			});
		});
	}

	function testObservedAttributes() {
		final attrs:Array<String> = js.Syntax.code("customElements.get('test-sub').observedAttributes");
		attrs.sort(Reflect.compare);
		Assert.same(["count", "data-items", "enabled", "is-flag", "label", "step"], attrs);
	}

	function testLightDom(async:Async) {
		final el:LightElement = mount(cast document.createElement("test-light"));
		el.updateComplete.then(_ -> {
			Assert.isNull(el.shadowRoot);
			Assert.equals("<span>light</span>", text(el));
			async.done();
		});
	}

	function testConstructWithNew(async:Async) {
		final el = mount(new Counter());
		el.updateComplete.then(_ -> {
			Assert.equals("TEST-COUNTER", el.tagName);
			async.done();
		});
	}
}

class Upper extends Directive {
	public function new(partInfo:PartInfo) {
		super(partInfo);
	}

	function render(s:String)
		return s.toUpperCase();
}

final upper:(s:String) -> DirectiveResult = Directive.create(Upper);

class TestDirectives extends utest.Test {
	var div:DivElement;

	function setup()
		div = document.createDivElement();

	function testClassMap() {
		render(html('<p class=${classMap({a: true, b: false, "c-d": true})}></p>'), div);
		Assert.equals("a c-d", StringTools.trim(div.querySelector("p").className));
	}

	function testStyleMap() {
		render(html('<p style=${styleMap({color: "red", "--x": "1"})}></p>'), div);
		final style = div.querySelector("p").style;
		Assert.equals("red", style.color);
		Assert.equals("1", style.getPropertyValue("--x"));
	}

	function testRepeat() {
		final items = [{id: 1, n: "a"}, {id: 2, n: "b"}];
		function tpl()
			return html('<ul>${repeat(items, i -> i.id, i -> html('<li>${i.n}</li>'))}</ul>');
		render(tpl(), div);
		final first = div.querySelector("li");
		items.reverse();
		render(tpl(), div);
		Assert.equals("<ul><li>b</li><li>a</li></ul>", text(div));
		Assert.equals(first, cast div.querySelectorAll("li")[1]);
		render(html('${repeat(["x", "y"], (s, i) -> html('<i>${i}${s}</i>'))}'), div);
		Assert.equals("<i>0x</i><i>1y</i>", text(div));
	}

	function testWhen() {
		render(html('${when(true, () -> "yes", () -> "no")}|${when(false, () -> "yes", () -> "no")}|${when(false, () -> "yes")}'), div);
		Assert.equals("yes|no|", text(div));
	}

	function testChoose() {
		final cases:Array<Array<Dynamic>> = [["a", () -> "A"], ["b", () -> "B"]];
		render(html('${choose("b", cases)}${choose("z", cases, () -> "default")}'), div);
		Assert.equals("Bdefault", text(div));
	}

	function testMapJoinRange() {
		render(html('${join(map(["a", "b"], (s, i) -> '$s$i'), ",")}|${range(3)}|${range(1, 7, 2)}'), div);
		Assert.equals("a0,b1|012|135", text(div));
	}

	function testIfDefined() {
		final v:Null<String> = null;
		render(html('<a href=${ifDefined(v)}></a><b title=${ifDefined("t")}></b>'), div);
		Assert.isFalse(div.querySelector("a").hasAttribute("href"));
		Assert.equals("t", div.querySelector("b").title);
	}

	function testRef() {
		final r = createRef();
		var cb:Element = null;
		render(html('<input ${ref(r)}><p ${ref(el -> cb = el)}></p>'), div);
		Assert.equals("input", r.value.localName);
		Assert.equals("p", cb.localName);
	}

	function testUnsafeHTML() {
		render(html('${unsafeHTML("<b>bold</b>")}'), div);
		Assert.equals("<b>bold</b>", text(div));
	}

	function testCustomDirective() {
		render(html('<p>${upper("hi")}</p>'), div);
		Assert.equals("<p>HI</p>", text(div));
	}

	function testUntil(async:Async) {
		final p = new js.lib.Promise<String>((resolve, _) -> resolve("done"));
		render(html('${until(p, "loading")}'), div);
		Assert.equals("loading", text(div));
		p.then(_ -> js.Browser.window.setTimeout(() -> {
			Assert.equals("done", text(div));
			async.done();
		}, 0));
	}
}

typedef Picked = {
	final id:Int;
	final label:String;
}

@:customElement("test-picker")
class Picker extends LitElement {
	public static final PICK = new EventType<Picked>("pick");
	public static final CLOSE = new EventType<Void>("close");
	public static final LOCAL = new EventType<String>("local", {bubbles: false, composed: false, cancelable: true});

	override function render()
		return html('<button id="pick" @click=${() -> PICK.dispatch(this, {id: 1, label: "one"})}></button><button id="close" @click=${() -> CLOSE.dispatch(this)}></button>');
}

class TestEvents extends utest.Test {
	var picked:Array<Picked>;
	var closed:Int;

	function setup() {
		picked = [];
		closed = 0;
	}

	function onPick(p:Picked)
		picked.push(p);

	function onClose()
		closed++;

	function testTemplateListen(async:Async) {
		final div = document.createDivElement();
		mount(div);
		render(html('<test-picker @pick=${Picker.PICK.listen(onPick)} @close=${Picker.CLOSE.listen(onClose)}></test-picker>'), div);
		final el:Picker = cast div.querySelector("test-picker");
		el.updateComplete.then(_ -> {
			(cast el.shadowRoot.querySelector("#pick") : js.html.Element).click();
			(cast el.shadowRoot.querySelector("#close") : js.html.Element).click();
			Assert.equals(1, picked.length);
			Assert.equals("one", picked[0].label);
			Assert.equals(1, closed);
			div.remove();
			async.done();
		});
	}

	function testListenerIsCached() {
		Assert.equals(Picker.PICK.listen(onPick), Picker.PICK.listen(onPick));
		Assert.notEquals(Picker.PICK.listen(onPick), Picker.PICK.listen(p -> onPick(p)));
	}

	function testBubblesAndComposed() {
		final outer = document.createDivElement();
		final picker = new Picker();
		outer.appendChild(picker);
		final off = Picker.PICK.on(outer, onPick);
		Picker.PICK.dispatch(picker, {id: 2, label: "two"});
		off();
		Picker.PICK.dispatch(picker, {id: 3, label: "three"});
		Assert.same([2], picked.map(p -> p.id));
	}

	function testOptions() {
		final outer = document.createDivElement();
		final picker = new Picker();
		outer.appendChild(picker);
		var outerCalls = 0;
		Picker.LOCAL.on(outer, (_:String) -> outerCalls++);
		Assert.isTrue(Picker.LOCAL.dispatch(picker, "x"));
		Assert.equals(0, outerCalls);
		// cancelable: the raw event is available to plain listeners
		picker.addEventListener("local", (e:js.html.Event) -> e.preventDefault());
		Assert.isFalse(Picker.LOCAL.dispatch(picker, "y"));
		Assert.equals("local", '${Picker.LOCAL}');
	}
}
