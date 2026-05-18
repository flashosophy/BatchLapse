import { createHash } from "node:crypto";
import { readdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { join, relative } from "node:path";

const root = new URL("..", import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, "$1");
const packageJson = JSON.parse(readFileSync(join(root, "package.json"), "utf8"));
const includeDirs = ["src", "src-tauri/src", "src-tauri/capabilities", "scripts"];
const includeFiles = ["index.html", "package.json", "src-tauri/Cargo.toml", "src-tauri/tauri.conf.json"];
const skipFiles = new Set(["src/build-info.ts"]);

function walk(dir, files = []) {
  for (const entry of readdirSync(dir)) {
    const fullPath = join(dir, entry);
    const rel = relative(root, fullPath).replaceAll("\\", "/");
    if (skipFiles.has(rel)) continue;
    const stat = statSync(fullPath);
    if (stat.isDirectory()) {
      walk(fullPath, files);
    } else {
      files.push(rel);
    }
  }
  return files;
}

const files = [
  ...includeFiles,
  ...includeDirs.flatMap((dir) => walk(join(root, dir)))
].sort();

const hash = createHash("sha256");
for (const file of files) {
  hash.update(file);
  hash.update("\0");
  hash.update(readFileSync(join(root, file)));
  hash.update("\0");
}

const buildHash = hash.digest("hex").slice(0, 8);
writeFileSync(
  join(root, "src", "build-info.ts"),
  `export const APP_VERSION = ${JSON.stringify(packageJson.version)};\nexport const BUILD_HASH = ${JSON.stringify(buildHash)};\n`
);
