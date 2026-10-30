package summ.ui;

import js.Browser.window;
import lit.ReactiveController;

/**
	Requests a host update every `interval` ms while connected and running.
**/
class TickController implements ReactiveController {
	public var running(default, set) = false;

	final host:ReactiveControllerHost;
	final interval:Int;
	var timer:Null<Int>;

	public function new(host:ReactiveControllerHost, interval = 1000) {
		this.host = host;
		this.interval = interval;
		host.addController(this);
	}

	function set_running(v:Bool) {
		running = v;
		v ? start() : stop();
		return v;
	}

	function start() {
		if (timer == null)
			timer = window.setInterval(host.requestUpdate, interval);
	}

	function stop() {
		if (timer != null) {
			window.clearInterval(timer);
			timer = null;
		}
	}

	function hostConnected()
		if (running)
			start();

	function hostDisconnected()
		stop();
}

/** Formats a duration since `since`, like `1:05` **/
function elapsed(since:Date):String {
	final s = Std.int((Date.now().getTime() - since.getTime()) / 1000);
	return '${Std.int(s / 60)}:${StringTools.lpad(Std.string(s % 60), "0", 2)}';
}
