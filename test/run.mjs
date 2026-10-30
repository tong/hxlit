// Runs the test bundle inside a jsdom window
import { readFileSync } from "node:fs";
import { JSDOM, VirtualConsole } from "jsdom";

const virtualConsole = new VirtualConsole();
virtualConsole.forwardTo(console);
const dom = new JSDOM("<!doctype html><html><body></body></html>", {
	runScripts: "outside-only",
	pretendToBeVisual: true,
	virtualConsole,
});
const done = new Promise(resolve => (dom.window.onTestsDone = resolve));
dom.window.eval(readFileSync(new URL("../bin/test.bundle.js", import.meta.url), "utf8"));
const success = await done;
process.exit(success ? 0 : 1);
