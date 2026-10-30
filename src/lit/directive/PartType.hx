package lit.directive;

enum abstract PartType(Int) to Int {
	var ATTRIBUTE = 1;
	var CHILD = 2;
	var PROPERTY = 3;
	var BOOLEAN_ATTRIBUTE = 4;
	var EVENT = 5;
	var ELEMENT = 6;
}
