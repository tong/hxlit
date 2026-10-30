package lit.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.PositionTools;

/**
	Turns a string literal into a native JS tagged template literal.
**/
class Template {
	public static function build(tag:Expr, template:Expr, type:ComplexType):Expr {
		final parts = parse(template);
		for (i in 0...parts.exprs.length)
			checkEventBinding(parts.strings[i], parts.exprs[i]);
		final code = new StringBuf();
		code.add("{0}`");
		for (i in 0...parts.strings.length) {
			code.add(escape(parts.strings[i]));
			if (i < parts.exprs.length)
				code.add("${{" + (i + 1) + "}}");
		}
		code.add("`");
		final args = [macro $v{code.toString()}, tag].concat(parts.exprs);
		final call = {expr: ECall(macro js.Syntax.code, args), pos: template.pos};
		return macro @:pos(template.pos) ($call : $type);
	}

	static final EVENT_BINDING = ~/@([^\s=>\/"']+)=["']?$/;

	/**
		Checks `@name=${TYPE.listen(f)}` bindings against the name of the `EventType`,
		when `TYPE` is a static field initialized with `new EventType("literal")`.
	**/
	static function checkEventBinding(before:String, e:Expr) {
		if (Context.defined("display") || !EVENT_BINDING.match(before))
			return;
		final binding = EVENT_BINDING.matched(1);
		final receiver = switch e.expr {
			case ECall({expr: EField(r, "listen")}, _): r;
			case _: return;
		}
		final name = try switch Context.typeExpr(receiver).expr {
			case TField(_, FStatic(_, _.get().expr() => {expr: TNew(_.get() => {pack: ["lit"], name: "EventType"}, _, args)})):
				switch args[0].expr {
					case TConst(TString(n)): n;
					case _: null;
				}
			case _: null;
		} catch (_)
			null;
		if (name != null && name != binding)
			Context.error('Event binding @$binding uses EventType "$name"', receiver.pos);
	}

	/**
		Splits the template into static strings and interpolated expressions, following haxe interpolation rules:
		`${expr}`, `$ident` and `$$` (single quoted strings and inline markup only).
	**/
	static function parse(template:Expr):{strings:Array<String>, exprs:Array<Expr>} {
		function source(s:String, pos:Position, offset:Int) {
			final info = pos.getInfos();
			Tags.collect(s, info.file, info.min + offset);
		}
		return switch template.expr {
			case EConst(CString(s, DoubleQuotes)):
				source(s, template.pos, 1);
				{strings: [s], exprs: []};
			case EMeta({name: ":markup"}, {expr: EConst(CString(s, _)), pos: pos}):
				// Inline markup `<div>...</div>`, position starts at `<`
				source(s, pos, 0);
				interpolate(s, pos, 0);
			case EConst(CString(s, _)):
				source(s, template.pos, 1);
				interpolate(s, template.pos, 1);
			case EParenthesis(e) | EMeta(_, e):
				parse(e);
			case _:
				Context.error("String literal expected", template.pos);
		}
	}

	static function interpolate(s:String, pos:Position, offset:Int):{strings:Array<String>, exprs:Array<Expr>} {
		final strings = new Array<String>();
		final exprs = new Array<Expr>();
		final info = pos.getInfos();
		var buf = new StringBuf();
		var i = 0;
		inline function code(at)
			return StringTools.fastCodeAt(s, at);
		inline function isIdentStart(c)
			return (c >= 'a'.code && c <= 'z'.code) || (c >= 'A'.code && c <= 'Z'.code) || c == '_'.code;
		inline function isIdent(c)
			return isIdentStart(c) || (c >= '0'.code && c <= '9'.code);
		function addExpr(src:String, start:Int) {
			final p = Context.makePosition({file: info.file, min: info.min + offset + start, max: info.min + offset + start + src.length});
			if (StringTools.trim(src) == "")
				Context.error("Empty interpolation", p);
			strings.push(buf.toString());
			buf = new StringBuf();
			exprs.push(Context.parseInlineString(src, p));
		}
		while (i < s.length) {
			final c = code(i);
			if (c != '$'.code || i + 1 >= s.length) {
				buf.addChar(c);
				i++;
				continue;
			}
			final n = code(i + 1);
			if (n == '$'.code) {
				buf.addChar('$'.code);
				i += 2;
			} else if (n == '{'.code) {
				final start = i + 2;
				var depth = 1;
				var j = start;
				var quote = -1;
				while (j < s.length) {
					final d = code(j);
					if (quote != -1) {
						if (d == '\\'.code)
							j++;
						else if (d == quote)
							quote = -1;
					} else if (d == '"'.code || d == "'".code) {
						quote = d;
					} else if (d == '{'.code) {
						depth++;
					} else if (d == '}'.code) {
						if (--depth == 0)
							break;
					}
					j++;
				}
				if (depth != 0)
					Context.error("Unclosed interpolation", pos);
				addExpr(s.substring(start, j), start);
				i = j + 1;
			} else if (isIdentStart(n)) {
				var j = i + 1;
				while (j < s.length && isIdent(code(j)))
					j++;
				addExpr(s.substring(i + 1, j), i + 1);
				i = j;
			} else {
				buf.addChar(c);
				i++;
			}
		}
		strings.push(buf.toString());
		return {strings: strings, exprs: exprs};
	}

	/**
		Escapes a string for use inside a JS template literal emitted by `js.Syntax.code`.
	**/
	static function escape(s:String):String {
		s = StringTools.replace(s, "\\", "\\\\");
		s = StringTools.replace(s, "`", "\\`");
		s = StringTools.replace(s, "${", "\\${");
		// `{0}` would be substituted by js.Syntax.code
		return ~/\{([0-9]+)\}/g.replace(s, "\\u007B$1}");
	}
}
#end
