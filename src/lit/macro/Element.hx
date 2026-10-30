package lit.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.ComplexTypeTools;
using haxe.macro.TypeTools;

/**
	Build macro for subclasses of `ReactiveElement`/`LitElement`.

	Class metadata:

	- `@:customElement("tag-name")` registers the element with `customElements.define`.

	Field metadata:

	- `@:property` / `@:property({reflect: true, attribute: "my-attr"})` declares a reactive property.
	  The `type` option is inferred from the field type (`Int`/`Float` → `Number`, `Bool` → `Boolean`, `String`, `Array`, else `Object`).
	- `@:state` / `@:state({hasChanged: ...})` declares internal reactive state.
	- `@:query("#selector")` turns the field into a getter returning `renderRoot.querySelector(selector)`.
	- `@:queryAll(".selector")` turns the field into a getter returning `renderRoot.querySelectorAll(selector)`.

	Also:

	- Field initializers are moved into the constructor after `super()`, which is required for classes extending externs.
	  A constructor is generated if missing.
	- Overridden methods (lifecycle callbacks) and the static fields `styles` and `shadowRootOptions` are kept from dead code elimination.
	- Reactive properties are registered with `createProperty` (a static `properties` field is not possible, it collides with `js.html.Element.properties`).
**/
class Element {
	static final KEEP_STATICS = ["styles", "shadowRootOptions"];

	public static function build():Null<Array<Field>> {
		final cl = Context.getLocalClass().get();
		if (cl.isExtern)
			return null;
		final es = Std.parseInt(Context.definedValue("js-es"));
		if (es == null || es < 6)
			Context.error("Custom elements require ES6 classes, compile with -D js-es=6", Context.currentPos());
		final fields = Context.getBuildFields();
		final pos = Context.currentPos();
		final declarations = new Array<{field:String, expr:Expr}>();
		final inits = new Array<Expr>();
		final extra = new Array<Field>();
		var ctor:Null<Field> = null;

		for (f in fields) {
			if (f.name == "new") {
				ctor = f;
				continue;
			}
			final isStatic = f.access != null && f.access.contains(AStatic);
			if (isStatic) {
				if (KEEP_STATICS.contains(f.name))
					keep(f);
				continue;
			}
			// Lifecycle methods are only called by lit
			if (f.access != null && f.access.contains(AOverride))
				keep(f);
			if (f.meta != null) for (m in f.meta) {
				switch m.name {
					case ":property", ":state":
						declarations.push({field: f.name, expr: declaration(f, m, m.name == ":state")});
					case ":query", ":queryAll":
						extra.push(query(f, m));
					case _:
				}
			}
			switch f.kind {
				case FVar(t, e) if (e != null):
					f.kind = FVar(t != null ? t : typeOf(f, e), null);
					final name = f.name;
					inits.push(macro @:pos(e.pos) this.$name = $e);
				case FProp(get, set, t, e) if (e != null):
					f.kind = FProp(get, set, t != null ? t : typeOf(f, e), null);
					final name = f.name;
					inits.push(macro @:pos(e.pos) @:bypassAccessor this.$name = $e);
				case _:
			}
		}

		if (declarations.length > 0) {
			// `static properties` collides with `js.html.Element.properties`, use `createProperty` instead
			final self = macro $i{cl.name};
			final calls = new Array<Expr>();
			for (d in declarations) {
				// Haxe adds `field: null` to the prototype when reflection is used,
				// lit would wrap it as user defined accessor (without getter/setter)
				calls.push(macro js.Syntax.code("delete {0}.prototype[{1}]", $self, $v{d.field}));
				calls.push(macro js.Syntax.code("{0}.createProperty({1}, {2})", $self, $v{d.field}, ${d.expr}));
			}
			// First field, initialized before the element gets defined
			fields.unshift({
				name: "__litProperties__",
				access: [AStatic],
				kind: FVar(macro :Bool, macro {
					$b{calls};
					true;
				}),
				meta: [{name: ":keep", pos: pos}, {name: ":noCompletion", pos: pos}],
				pos: pos
			});
		}

		if (inits.length > 0) {
			if (ctor == null) {
				fields.push({
					name: "new",
					access: [APublic],
					kind: FFun({args: [], expr: macro {super();}}),
					pos: pos
				});
				ctor = fields[fields.length - 1];
			}
			switch ctor.kind {
				case FFun(fn):
					fn.expr = insertAfterSuper(fn.expr, inits, ctor.pos);
				case _:
			}
		}

		for (f in extra)
			fields.push(f);

		final tag = cl.meta.extract(":customElement")[0];
		if (tag != null) {
			if (tag.params == null || tag.params.length != 1)
				Context.error("@:customElement requires the tag name", tag.pos);
			final name = tag.params[0];
			final self = macro $i{cl.name};
			// Last field, initialized after `__litProperties__` and `styles`
			fields.push({
				name: "__litDefine__",
				access: [AStatic],
				kind: FVar(macro :Bool, macro {
					if (js.Syntax.code("customElements.get({0})", $name) == null)
						js.Syntax.code("customElements.define({0}, {1})", $name, $self);
					true;
				}),
				meta: [{name: ":keep", pos: tag.pos}, {name: ":noCompletion", pos: tag.pos}],
				pos: tag.pos
			});
		}

		return fields;
	}

	static function declaration(f:Field, m:MetadataEntry, state:Bool):Expr {
		final out = new Array<ObjectField>();
		if (m.params != null && m.params.length > 0) {
			switch m.params[0].expr {
				case EObjectDecl(fs):
					for (o in fs)
						out.push(o.field == "type" ? {field: o.field, expr: typeOption(o.expr)} : o);
				case _:
					Context.error('@${m.name} expects an object of property options', m.params[0].pos);
			}
		}
		inline function has(name:String)
			return Lambda.exists(out, o -> o.field == name);
		if (state && !has("state"))
			out.push({field: "state", expr: macro true});
		if (!state && !has("type")) {
			final type = typeHint(f);
			if (type != null)
				out.push({field: "type", expr: macro js.Syntax.code($v{type})});
		}
		return {expr: EObjectDecl(out), pos: m.pos};
	}

	/** Maps JS (`Boolean`, `Number`, `Object`) and haxe (`Bool`, `Int`, `Float`) type names to the JS constructor. **/
	static function typeOption(e:Expr):Expr {
		final name = switch e.expr {
			case EConst(CIdent("Boolean" | "Bool")): "Boolean";
			case EConst(CIdent("Number" | "Int" | "Float")): "Number";
			case EConst(CIdent("Object")): "Object";
			case EConst(CIdent("String")): "String";
			case EConst(CIdent("Array")): "Array";
			case _: return e;
		}
		return macro @:pos(e.pos) js.Syntax.code($v{name});
	}

	/** Maps the field type to the lit type hint for attribute conversion. **/
	static function typeHint(f:Field):Null<String> {
		final t:Null<Type> = try switch f.kind {
			case FVar(t, e), FProp(_, _, t, e):
				if (t != null) t.toType() else if (e != null) Context.typeof(e) else null;
			case FFun(_): null;
		} catch (_) null;
		if (t == null)
			return null;
		return switch Context.followWithAbstracts(t) {
			case TAbstract(_.get() => {pack: [], name: "Int" | "Float" | "UInt"}, _): "Number";
			case TAbstract(_.get() => {pack: [], name: "Bool"}, _): "Boolean";
			case TInst(_.get() => {pack: [], name: "String"}, _): "String";
			case TInst(_.get() => {pack: [], name: "Array"}, _): "Array";
			case TMono(_), TDynamic(_): null;
			case _: "Object";
		}
	}

	static function query(f:Field, m:MetadataEntry):Field {
		if (m.params == null || m.params.length != 1)
			Context.error('@${m.name} requires a selector', m.pos);
		final selector = m.params[0];
		final t = switch f.kind {
			case FVar(t, null) if (t != null): t;
			case _: Context.error('@${m.name} requires a typed variable without initializer', f.pos);
		}
		f.kind = FProp("get", "never", t);
		final body = m.name == ":query" ? macro cast renderRoot.querySelector($selector) : macro cast renderRoot.querySelectorAll($selector);
		return {
			name: "get_" + f.name,
			access: [AInline],
			kind: FFun({args: [], ret: t, expr: macro return $body}),
			pos: f.pos
		};
	}

	static function insertAfterSuper(body:Null<Expr>, inits:Array<Expr>, pos:Position):Expr {
		function isSuperCall(e:Expr)
			return switch e.expr {
				case ECall({expr: EConst(CIdent("super"))}, _): true;
				case _: false;
			}
		if (body == null)
			Context.error("Constructor requires a body", pos);
		final exprs = switch body.expr {
			case EBlock(exprs): exprs.copy();
			case _: [body];
		}
		for (i in 0...exprs.length) {
			if (isSuperCall(exprs[i])) {
				return {expr: EBlock(exprs.slice(0, i + 1).concat(inits).concat(exprs.slice(i + 1))), pos: body.pos};
			}
		}
		return Context.error("Constructor must call super() at top level when fields have initializers", pos);
	}

	static function typeOf(f:Field, e:Expr):ComplexType {
		switch e.expr {
			case ENew(tp, _):
				return TPath(tp);
			case ECheckType(_, t):
				return t;
			case EParenthesis(e):
				return typeOf(f, e);
			case _:
		}
		final t = try Context.typeof(e).toComplexType() catch (_) null;
		return t != null ? t : Context.error('Type hint required for field ${f.name}: lit element initializers are moved into the constructor and their type can\'t be inferred here', f.pos);
	}

	static function keep(f:Field) {
		if (f.meta == null)
			f.meta = [];
		f.meta.push({name: ":keep", pos: f.pos});
	}
}
#end
