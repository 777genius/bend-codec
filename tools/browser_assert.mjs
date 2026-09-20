import { readdir } from "node:fs/promises";
import { join } from "node:path";
import { pathToFileURL } from "node:url";

const dir = process.argv[2];
if (!dir) {
  console.error("usage: browser_assert.mjs <smoke_out_dir>");
  process.exit(2);
}

const chunk = (await readdir(dir)).find(
  (name) => name.startsWith("chunk-") && name.endsWith(".js"),
);
if (chunk === undefined) {
  console.error("e2e: no bundled chunk in", dir);
  process.exit(1);
}

const document = { body: { textContent: "" } };
globalThis.document = document;
await import(pathToFileURL(join(dir, chunk)).href);
const got = String(document.body.textContent ?? "").replace(/\r/g, "").trim();
if (got !== "0001feff") {
  console.error("e2e: browser artefact:", got);
  process.exit(1);
}
console.log("0001feff");
