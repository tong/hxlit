package lit.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

/**
	Warns about custom element tags used in templates without a compiled class defining them
	(usually a missing import: classes only referenced by their tag name are not compiled).

	Any class with `@:customElement("tag-name")` metadata defines a tag, including externs,
	which can be used to declare third party elements.

	Disable with `-D lit-no-tag-check`.
**/
class Tags {
	static final TAG = ~/<([a-z][a-z0-9._]*-[a-z0-9._-]*)/;
	static var used:Null<Map<String, Position>>;

	/** Collects custom element tags of a template source, `offset` is the source position of `s`. **/
	public static function collect(s:String, file:String, offset:Int) {
		if (Context.defined("lit-no-tag-check"))
			return;
		if (used == null) {
			used = [];
			Context.onAfterTyping(check);
		}
		var start = 0;
		while (TAG.matchSub(s, start)) {
			final tag = TAG.matched(1);
			final p = TAG.matchedPos();
			if (!used.exists(tag))
				used.set(tag, Context.makePosition({file: file, min: offset + p.pos + 1, max: offset + p.pos + 1 + tag.length}));
			start = p.pos + p.len;
		}
	}

	static function check(types:Array<ModuleType>) {
		if (used == null)
			return;
		final defined = new Map<String, Bool>();
		for (t in types) {
			switch t {
				case TClassDecl(_.get() => c):
					for (m in c.meta.extract(":customElement"))
						switch m.params {
							case [{expr: EConst(CString(tag))}]: defined.set(tag, true);
							case _:
						}
				case _:
			}
		}
		for (tag => pos in used)
			if (!defined.exists(tag))
				Context.warning('Custom element <$tag> is not defined by any compiled class (missing import?)', pos);
		used = null;
	}
}
#end
