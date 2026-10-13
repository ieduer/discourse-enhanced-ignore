// Lets the pure-logic QUnit files in test/unit run under plain Node, without
// a Discourse checkout. It only does three things:
//   * maps `qunit` to a tiny shim built on node:test,
//   * maps the theme-relative `discourse/...` path used by Discourse's theme
//     test runner to `javascripts/discourse/...`,
//   * treats the theme's .js files as ES modules.
// Anything that needs Ember or Discourse itself is out of scope here.
import { existsSync } from "node:fs";
import { readFile } from "node:fs/promises";
import { dirname, resolve as resolvePath } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const root = resolvePath(dirname(fileURLToPath(import.meta.url)), "..");
const shim = pathToFileURL(resolvePath(root, "scripts/qunit-shim.mjs")).href;

export async function resolve(specifier, context, nextResolve) {
  if (specifier === "qunit") {
    return { url: shim, shortCircuit: true };
  }

  if (specifier.startsWith(".") && context.parentURL?.startsWith("file:")) {
    const parentDir = dirname(fileURLToPath(context.parentURL));
    let target = resolvePath(parentDir, specifier);

    const themeRoot = resolvePath(root, "discourse");
    if (target.startsWith(themeRoot)) {
      target = resolvePath(root, "javascripts", target.slice(root.length + 1));
    }
    if (!existsSync(target) && existsSync(`${target}.js`)) {
      target = `${target}.js`;
    }
    return { url: pathToFileURL(target).href, shortCircuit: true };
  }

  return nextResolve(specifier, context);
}

export async function load(url, context, nextLoad) {
  if (url.startsWith(pathToFileURL(root).href) && url.endsWith(".js")) {
    return {
      format: "module",
      source: await readFile(fileURLToPath(url), "utf8"),
      shortCircuit: true,
    };
  }
  return nextLoad(url, context);
}
