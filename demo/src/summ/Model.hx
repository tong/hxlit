package summ;

enum abstract Presence(String) to String {
	var Online = "online";
	var Away = "away";
	var Dnd = "dnd";
	var Offline = "offline";
}

enum RequestState {
	Idle;
	Connecting;
	Waiting(since:Date);
	Accepted;
	Declined(reason:Null<String>);
	Revoked;
	Failed(error:String);
}

enum CallState {
	NoCall;
	Ringing(video:Bool);
	Active(video:Bool, started:Date);
	Ended(reason:String);
}

enum abstract ChatState(String) to String {
	var Active = "active";
	var Composing = "composing";
	var Paused = "paused";
}

typedef Message = {
	final id:String;
	final from:String;
	final body:String;
	final time:Date;
	final outgoing:Bool;
	var ?received:Bool;
	var ?corrected:Bool;
}

typedef Request = {
	final nick:String;
	final text:String;
	final ?contact:String;
}
