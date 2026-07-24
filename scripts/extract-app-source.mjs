import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const indexPath = path.join(root, "index.html");
const appPath = path.join(root, "src", "app.jsx");
const html = fs.readFileSync(indexPath, "utf8");
const opening = '<script type="text/babel">';
const start = html.indexOf(opening);
const end = start >= 0 ? html.indexOf("</script>", start + opening.length) : -1;

if (start < 0 || end < 0) {
  throw new Error("Could not find the inline JSX application in index.html");
}

const source = html.slice(start + opening.length, end).trimStart();
fs.writeFileSync(appPath, source);
const updated = html.slice(0, start) + '<script src="/app.js" defer></script>\n' + html.slice(end + "</script>".length);
fs.writeFileSync(indexPath, updated);
console.log(`Extracted ${source.split("\n").length} lines to src/app.jsx.`);
