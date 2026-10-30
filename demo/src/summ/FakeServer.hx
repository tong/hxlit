package summ;

import js.Browser.window;
import js.lib.Promise;
import summ.Model;

/**
	Simulates the XMPP side: the owner accepts the request, answers messages, picks up calls.
**/
class FakeServer {
	public var onPresence:Presence->Void = _ -> {};
	public var onMessage:Message->Void = _ -> {};
	public var onReceipt:String->Void = _ -> {};
	public var onChatState:ChatState->Void = _ -> {};
	public var onRequest:RequestState->Void = _ -> {};
	public var onCall:CallState->Void = _ -> {};

	final owner:String;
	var nextId = 0;

	public function new(owner:String) {
		this.owner = owner;
	}

	public function connect():Promise<String> {
		return new Promise((resolve, reject) -> {
			window.setTimeout(() -> resolve('${StringTools.hex(Std.random(0xffffff))}@anon.example.org/web'), 600);
		});
	}

	public function sendRequest(req:Request) {
		onRequest(Waiting(Date.now()));
		later(1500, () -> {
			if (req.text.toLowerCase().indexOf("spam") != -1) {
				onRequest(Declined("Looks like spam"));
				return;
			}
			onRequest(Accepted);
			onPresence(Online);
			later(800, () -> reply('Hi ${req.nick}, thanks for reaching out!'));
		});
	}

	public function send(body:String):Message {
		final msg:Message = {id: id(), from: "me", body: body, time: Date.now(), outgoing: true};
		later(300, () -> onReceipt(msg.id));
		later(700, () -> onChatState(Composing));
		later(2000, () -> reply(answer(body)));
		return msg;
	}

	public function call(video:Bool) {
		onCall(Ringing(video));
		later(2000, () -> onCall(Active(video, Date.now())));
	}

	public function hangup() {
		onCall(Ended("You hung up"));
		later(1500, () -> onCall(NoCall));
	}

	function reply(body:String) {
		onChatState(Active);
		onMessage({id: id(), from: owner, body: body, time: Date.now(), outgoing: false});
	}

	function answer(body:String):String {
		return switch body.toLowerCase() {
			case s if (s.indexOf("away") != -1):
				later(500, () -> onPresence(Away));
				"I'll be away for a moment.";
			case s if (s.indexOf("?") != -1): "Good question!";
			case _: 'You said: "$body"';
		}
	}

	function id()
		return 'm${nextId++}';

	static function later(ms:Int, f:Void->Void)
		window.setTimeout(f, ms);
}
