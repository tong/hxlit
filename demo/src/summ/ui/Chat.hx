package summ.ui;

import js.html.DivElement;
import js.html.KeyboardEvent;
import js.html.TextAreaElement;
import lit.Directives.*;
import lit.EventType;
import lit.Lit.*;
import lit.LitElement;
import lit.PropertyValues;
import summ.Model;

@:customElement("summ-message")
class ChatMessage extends LitElement {
	static var styles = css('
		:host { display: flex; }
		:host([outgoing]) { justify-content: flex-end; }
		.bubble { max-width: 75%; padding: .4rem .7rem; border-radius: 12px; background: #eef1f6; }
		.body { white-space: pre-wrap; }
		:host([outgoing]) .bubble { background: var(--summ-accent, #3b6cf6); color: white; }
		.meta { font-size: .7em; opacity: .7; text-align: right; }
	');

	@:property({type: js.lib.Object}) public var message:Message;
	@:property({type: Boolean, reflect: true}) public var outgoing = false;

	override function willUpdate(changed:PropertyValues)
		if (changed.has("message"))
			outgoing = message.outgoing;

	override function render()
		return html(<div class="bubble">
			<div class="body">${message.body}</div>
			<div class="meta">
				${DateTools.format(message.time, "%H:%M")}
				${when(message.outgoing, () -> message.received == true ? "✓✓" : "✓")}
			</div>
		</div>);
}

/**
	Message list and input.
**/
@:customElement("summ-chat")
class Chat extends LitElement {
	static var styles = [
		Theme.base,
		css('
		:host { display: flex; flex-direction: column; gap: .5rem; }
		.log { display: flex; flex-direction: column; gap: .3rem; height: 18rem; overflow-y: auto; padding: .3rem; }
		.typing { font-size: .8em; color: #888; min-height: 1.2em; }
		.input { display: flex; gap: .5rem; }
		textarea { resize: none; }
	')
	];

	/** The user sends a message **/
	public static final SEND = new EventType<String>("send");

	@:property({attribute: false}) public var messages:Array<Message> = [];
	@:property public var peer = "";
	@:property public var chatState:ChatState = Active;
	@:property({type: Boolean}) public var disabled = false;

	@:query(".log") var log:DivElement;
	@:query("textarea") var input:TextAreaElement;

	override function updated(changed:PropertyValues) {
		if (changed.has("messages"))
			log.scrollTop = log.scrollHeight;
	}

	function send() {
		final body = StringTools.trim(input.value);
		if (body == "")
			return;
		SEND.dispatch(this, body);
		input.value = "";
	}

	function onKey(e:KeyboardEvent) {
		if (e.key == "Enter" && !e.shiftKey) {
			e.preventDefault();
			send();
		}
	}

	override function render()
		return html(<div>
			<div class="log">
				${repeat(messages, m -> m.id, m -> html(<summ-message .message=${m}></summ-message>))}
			</div>
			<div class="typing">${chatState == Composing ? '$peer is typing…' : nothing}</div>
			<div class="input">
				<textarea rows="2" placeholder="Message" @keydown=${onKey} ?disabled=${disabled}></textarea>
				<button @click=${send} ?disabled=${disabled}>Send</button>
			</div>
		</div>);
}
