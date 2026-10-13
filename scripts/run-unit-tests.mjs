import { readdirSync } from "node:fs";
import { register } from "node:module";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
register("./unit-loader.mjs", import.meta.url);

const directory = join(root, "test/unit/lib");
for (const file of readdirSync(directory).sort()) {
  if (file.endsWith("-test.js")) {
    await import(pathToFileURL(join(directory, file)).href);
  }
}
