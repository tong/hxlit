package summ.ui;

import lit.Directives.*;
import lit.Lit.*;
import lit.LitElement;
import summ.FakeServer;
import summ.Model;
import summ.ui.CallPanel;
import summ.ui.Card;
import summ.ui.Chat;
import summ.ui.Controllers;
import summ.ui.RequestForm;
import summ.ui.StatusBadge;

/**
	The page: request first, then chat and calls.
**/
@:customElement("summ-app")
class App extends LitElement {
	static var styles = [
		Theme.base,
		css('
		:host { display: block; max-width: 34rem; margin: auto; }
		summ-card + summ-card { margin-top: 1rem; }
		h1 { font-size: 1.1rem; margin: 0; flex: 1; }
		.muted { color: #777; font-size: .9em; }
		.jid { font-family: monospace; font-size: .8em; color: #888; }
	')
	];

	@:property public var owner = "owner@example.org";
	@:property({attribute: "owner-name"}) public var ownerName = "Owner";

	@:state var request:RequestState = Idle;
	@:state var jid:Null<String>;
	@:state var presence:Presence = Offline;
	@:state var messages:Array<Message> = [];
	@:state var chatState:ChatState = Active;
	@:state var call:CallState = NoCall;

	final ticker = new TickController(this, 1000);
	var server:FakeServer;

	override function connectedCallback() {
		super.connectedCallback();
		server = new FakeServer(owner);
		server.onRequest = s -> {
			request = s;
			ticker.running = s.match(Waiting(_));
		};
		server.onPresence = p -> presence = p;
		server.onChatState = s -> chatState = s;
		server.onMessage = m -> messages = messages.concat([m]);
		server.onReceipt = id -> messages = [
			for (m in messages) m.id == id ? {var c = Reflect.copy(m); c.received = true; c;} : m
		];
		server.onCall = c -> call = c;
	}

	function onRequest(req:Request) {
		request = Connecting;
		server.connect().then(jid -> {
			this.jid = jid;
			server.sendRequest(req);
		}).catchError(err -> request = Failed(Std.string(err)));
	}

	function onSend(body:String)
		messages = messages.concat([server.send(body)]);

	function reset() {
		request = Idle;
		messages = [];
		presence = Offline;
		jid = null;
	}

	function renderRequest()
		return switch request {
			case Idle | Connecting:
				html(<summ-request-form owner=${ownerName} ?disabled=${request == Connecting} @request=${RequestForm.REQUEST.listen(onRequest)}></summ-request-form>);
			case Waiting(since):
				html(<p class="muted">Waiting for ${ownerName} to answer… (${elapsed(since)})</p>);
			case Declined(reason):
				html(<p>Your request was declined${reason != null ? ': $reason' : ""}. <button class="secondary" @click=${reset}>Try again</button></p>);
			case Revoked:
				html(<p>${ownerName} ended the conversation.</p>);
			case Failed(error):
				html(<p>Could not connect: ${error} <button class="secondary" @click=${reset}>Retry</button></p>);
			case Accepted:
				nothing;
		}

	override function render() {
		final accepted = request == Accepted;
		return html(<div>
			<summ-card>
				<h1 slot="header">Talk to ${ownerName}</h1>
				<summ-status slot="header" presence=${presence} label=${ifDefined(accepted ? null : "unknown")}></summ-status>
				${cache(accepted
					? html(<summ-chat .messages=${messages} .chatState=${chatState} peer=${ownerName} @send=${Chat.SEND.listen(onSend)}></summ-chat>)
					: renderRequest())}
				<div slot="footer" class="jid">${jid ?? nothing}</div>
			</summ-card>
			<summ-card>
				<summ-call .state=${call} ?available=${accepted && presence != Offline}
					@call=${CallPanel.CALL.listen(server.call)}
					@hangup=${CallPanel.HANGUP.listen(server.hangup)}></summ-call>
			</summ-card>
		</div>);
	}
}
