package summ.ui;

import lit.Directives.*;
import lit.Lit.*;
import lit.LitElement;

/** Container with header, content and footer slots **/
@:customElement("summ-card")
class Card extends LitElement {
	static var styles = [
		Theme.base,
		css('
		:host { display: block; border: 1px solid #ddd; border-radius: 10px; background: white; overflow: hidden; }
		header { padding: .6rem 1rem; border-bottom: 1px solid #eee; display: flex; align-items: center; gap: .5rem; }
		main { padding: 1rem; }
		footer { padding: .6rem 1rem; border-top: 1px solid #eee; }
		.empty { display: none; }
	')
	];

	@:state var hasHeader = false;
	@:state var hasFooter = false;

	static function hasContent(e:js.html.Event):Bool
		return (cast e.target : js.html.SlotElement).assignedNodes().length > 0;

	override function render()
		return html(<div>
			<header class=${classMap({empty: !hasHeader})}><slot name="header" @slotchange=${e -> hasHeader = hasContent(e)}></slot></header>
			<main><slot></slot></main>
			<footer class=${classMap({empty: !hasFooter})}><slot name="footer" @slotchange=${e -> hasFooter = hasContent(e)}></slot></footer>
		</div>);
}
