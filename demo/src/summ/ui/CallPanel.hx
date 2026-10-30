package summ.ui;

import lit.Directives.*;
import lit.EventType;
import lit.Lit.*;
import lit.LitElement;
import lit.PropertyValues;
import summ.Model;
import summ.ui.Controllers;

/**
	Call controls.
**/
@:customElement("summ-call")
class CallPanel extends LitElement {
	static var styles = [Theme.base, css('
		:host { display: flex; gap: .5rem; align-items: center; flex-wrap: wrap; }
		.state { flex: 1; font-size: .9em; }
		.ringing { animation: pulse 1s infinite; }
		@keyframes pulse { 50% { opacity: .4; } }
	')];

	/** Start a call, `true` for video **/
	public static final CALL = new EventType<Bool>("call");

	/** Cancel or end the call **/
	public static final HANGUP = new EventType<Void>("hangup");

	/** Microphone muted or unmuted **/
	public static final MUTE = new EventType<Bool>("mute");

	@:property({attribute: false}) public var state:CallState = NoCall;
	@:property({type: Boolean}) public var available = false;
	@:state var muted = false;

	final ticker = new TickController(this);

	override function willUpdate(changed:PropertyValues) {
		if (changed.has("state")) {
			ticker.running = state.match(Active(_));
			if (!state.match(Active(_)))
				muted = false;
		}
	}

	function toggleMute() {
		muted = !muted;
		MUTE.dispatch(this, muted);
	}

	override function render()
		return html(<div style="display: contents">
			${switch state {
				case NoCall: html(<span style="display: contents">
					<span class="state">${available ? "Owner is available" : "Calls are possible once your request is accepted"}</span>
					<button @click=${() -> CALL.dispatch(this, false)} ?disabled=${!available}>Audio call</button>
					<button class="secondary" @click=${() -> CALL.dispatch(this, true)} ?disabled=${!available}>Video call</button>
				</span>);
				case Ringing(video): html(<span style="display: contents">
					<span class="state ringing">${video ? "Video" : "Audio"} call ringing…</span>
					<button class="danger" @click=${() -> HANGUP.dispatch(this)}>Cancel</button>
				</span>);
				case Active(video, started): html(<span style="display: contents">
					<span class="state">In ${video ? "video" : "audio"} call · ${elapsed(started)}</span>
					<button class="secondary" @click=${toggleMute}>${muted ? "Unmute" : "Mute"}</button>
					<button class="danger" @click=${() -> HANGUP.dispatch(this)}>Hang up</button>
				</span>);
				case Ended(reason): html(<span class="state">Call ended: ${reason}</span>);
			}}
		</div>);
}
