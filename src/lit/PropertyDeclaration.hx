package lit;

import haxe.extern.EitherType;

/**
	Options of a reactive property.

	@see https://lit.dev/docs/components/properties/#property-options
**/
typedef PropertyDeclaration = {
	/** Internal reactive state, not exposed as attribute. **/
	final ?state:Bool;

	/** Whether the property is associated with an attribute, or a custom attribute name. **/
	final ?attribute:EitherType<Bool, String>;

	/** Type hint for the default converter (`String`, `Number`, `Boolean`, `Array`, `Object`). **/
	final ?type:Any;

	final ?converter:AttributeConverter;

	/** Whether the property value is reflected back to the attribute. **/
	final ?reflect:Bool;

	/** Whether the property is considered changed when set. **/
	final ?hasChanged:(value:Any, oldValue:Any) -> Bool;

	/** Do not create a property accessor. **/
	final ?noAccessor:Bool;

	/** Do not reflect or set the attribute for the initial default value. **/
	final ?useDefault:Bool;
}

typedef ComplexAttributeConverter = {
	final ?fromAttribute:(value:Null<String>, ?type:Any) -> Any;
	final ?toAttribute:(value:Any, ?type:Any) -> Any;
}

typedef AttributeConverter = EitherType<ComplexAttributeConverter, (value:Null<String>, ?type:Any) -> Any>;
typedef PropertyDeclarations = haxe.DynamicAccess<PropertyDeclaration>;
