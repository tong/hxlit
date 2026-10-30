package summ.ui;

import lit.Directives.*;
import lit.Lit.*;
import lit.LitElement;
import summ.Model.Presence;

@:customElement("summ-status")
class StatusBadge extends LitElement {
	static var styles = css('
		:host { display: inline-flex; align-items: center; gap: .3rem; font-size: .85em; color: #555; }
		.dot { width: .6rem; height: .6rem; border-radius: 50%; }
	');

	static final colors = [Online => "#2fb344", Away => "#f59f00", Dnd => "#d63939", Offline => "#aaa"];

	@:property({reflect: true}) public var presence:Presence = Offline;
	@:property public var label:Null<String>;

	override function render()
		return html(<span>
			<span class="dot" style=${styleMap({background: colors[presence]})}></span>
			${label ?? presence}
		</span>);
}
