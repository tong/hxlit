package summ.ui;

import lit.Lit.css;

class Theme {
	public static final base = css('
		:host { box-sizing: border-box; font: inherit; color: var(--summ-fg, #222); }
		*, *::before, *::after { box-sizing: inherit; }
		button {
			font: inherit; border: 0; border-radius: var(--summ-radius, 6px); padding: .4rem .8rem; cursor: pointer;
			background: var(--summ-accent, #3b6cf6); color: white;
		}
		button:disabled { opacity: .5; cursor: default; }
		button.secondary { background: #e3e6ee; color: #222; }
		button.danger { background: #d9433b; }
		input, textarea { font: inherit; padding: .4rem; border: 1px solid #ccc; border-radius: var(--summ-radius, 6px); width: 100%; }
	');
}
