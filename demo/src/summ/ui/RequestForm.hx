package summ.ui;

import js.html.Event;
import js.html.InputElement;
import js.html.TextAreaElement;
import lit.Directives.*;
import lit.EventType;
import lit.Lit.*;
import lit.LitElement;
import lit.Ref;
import lit.PropertyValues;
import summ.Model;

/**
	The request form.
**/
@:customElement("summ-request-form")
class RequestForm extends LitElement {
	static var styles = [
		Theme.base,
		css('
		form { display: grid; gap: .7rem; }
		label { display: grid; gap: .2rem; font-size: .9em; }
		.error { color: #d63939; font-size: .85em; }
		.counter { justify-self: end; font-size: .8em; color: #888; }
		.counter.over { color: #d63939; }
	')
	];

	public static final REQUEST = new EventType<Request>("request");

	static inline final MAX_TEXT = 140;

	@:property public var owner = "the owner";
	@:property({type: Boolean}) public var disabled = false;

	@:state var nick = "";
	@:state var text = "";
	@:state var contact = "";
	@:state var errors:Array<String> = [];

	final nickInput:Ref<InputElement> = createRef();

	override function firstUpdated(changed:PropertyValues)
		nickInput.value?.focus();

	function submit(e:Event) {
		e.preventDefault();
		errors = validate();
		if (errors.length > 0)
			return;
		REQUEST.dispatch(this, {nick: nick, text: text, contact: contact == "" ? null : contact});
	}

	function validate():Array<String> {
		final errors = [];
		if (StringTools.trim(nick) == "")
			errors.push("Please enter your name");
		if (text.length > MAX_TEXT)
			errors.push('Message is too long (max $MAX_TEXT)');
		return errors;
	}

	override function render()
		return html(<form @submit=${submit}>
			<label>
				Your name
				<input ${ref(nickInput)} .value=${live(nick)} @input=${(e:Event) -> nick = (cast e.target : InputElement).value} ?disabled=${disabled} />
			</label>
			<label>
				Message to ${owner}
				<textarea rows="3" .value=${live(text)} @input=${(e:Event) -> text = (cast e.target : TextAreaElement).value} ?disabled=${disabled}></textarea>
				<span class=${classMap({counter: true, over: text.length > MAX_TEXT})}>${text.length}/${MAX_TEXT}</span>
			</label>
			<label>
				Contact (optional, email or jid)
				<input type="text" .value=${live(contact)} @input=${(e:Event) -> contact = (cast e.target : InputElement).value} ?disabled=${disabled} />
			</label>
			${errors.map(err -> html(<div class="error">${err}</div>))}
			<button type="submit" ?disabled=${disabled}>Send request</button>
		</form>);
}
