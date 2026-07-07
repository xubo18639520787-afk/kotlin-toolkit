#!/usr/bin/env node
// PreToolUse hook: blocks direct edits to generated files, pointing to the real source.

const fs = require("fs");

const GENERATED = [
  [
    "readium/navigator/src/main/assets/readium/scripts/",
    "This file is bundled from readium/navigator/src/main/assets/_scripts/. Edit the sources there, then run `make scripts-legacy` to rebundle.",
  ],
  [
    "readium/navigators/web/internals/src/main/assets/readium/navigator/web/internals/generated/",
    "This file is bundled from readium/navigators/web/internals/scripts/. Edit the sources there, then run `make scripts-new` to rebundle.",
  ],
  [
    "w3c_a11y_meta_display_guide_strings.xml",
    "This localization file is generated from the W3C repository by `make update-a11y-l10n`. Do not edit it by hand.",
  ],
];

function main() {
  let data;
  try {
    data = JSON.parse(fs.readFileSync(0, "utf8"));
  } catch {
    return;
  }
  const path = (data.tool_input && data.tool_input.file_path) || "";
  for (const [fragment, reason] of GENERATED) {
    if (path.includes(fragment)) {
      process.stdout.write(
        JSON.stringify({
          hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "deny",
            permissionDecisionReason: reason,
          },
        }) + "\n"
      );
      return;
    }
  }
}

main();
process.exit(0);
