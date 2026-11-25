#!/usr/bin/env python3
"""Check that the wrapper passes through every input and output of the pinned base module unchanged.

Usage: scripts/check-base-parity.py WRAPPER_DOCS.json BASE_DOCS.json main.tf
The JSON files come from `terraform-docs json` of this module and of the base module that `terraform init` downloaded
(make parity). Fails when an input or output is missing, has another type or description, or a default differs where
the wrapper doesn't mean it to.
"""

import json
import re
import sys

# Defaults the wrapper changes on purpose (README, "Defaults that differ")
INTENDED_DEFAULTS = {
    "name",
    "auth_enabled",
    "upstream_enabled",
    "upstream_cooldown_days",
}


def main(wrapper_path: str, base_path: str, main_tf: str) -> int:
    wrapper, base = (json.load(open(p)) for p in (wrapper_path, base_path))
    errors = []

    w_inputs = {i["name"]: i for i in wrapper["inputs"]}
    b_inputs = {i["name"]: i for i in base["inputs"]}
    for name in sorted(b_inputs.keys() - w_inputs.keys()):
        errors.append(f"input {name}: in the base module, missing in variables.tf")
    for name in sorted(w_inputs.keys() - b_inputs.keys()):
        errors.append(f"input {name}: not an input of the base module")
    for name in sorted(w_inputs.keys() & b_inputs.keys()):
        w, b = w_inputs[name], b_inputs[name]
        if w["type"] != b["type"]:
            errors.append(f"input {name}: type {w['type']!r}, base has {b['type']!r}")
        if w["description"] != b["description"]:
            errors.append(f"input {name}: description differs from the base module")
        if name not in INTENDED_DEFAULTS and w["default"] != b["default"]:
            errors.append(
                f"input {name}: default {w['default']!r}, base has {b['default']!r}"
            )
        if name in INTENDED_DEFAULTS and w["default"] == b["default"]:
            errors.append(
                f"input {name}: listed as an intended default change but equals the base default"
            )

    w_outputs = {o["name"]: o for o in wrapper["outputs"]}
    b_outputs = {o["name"]: o for o in base["outputs"]}
    for name in sorted(b_outputs.keys() - w_outputs.keys()):
        errors.append(f"output {name}: in the base module, missing in outputs.tf")
    for name in sorted(w_outputs.keys() - b_outputs.keys()):
        errors.append(f"output {name}: not an output of the base module")
    for name in sorted(w_outputs.keys() & b_outputs.keys()):
        if w_outputs[name]["description"] != b_outputs[name]["description"]:
            errors.append(f"output {name}: description differs from the base module")

    # Every input must reach the base module as `<name> = var.<name>`
    source = open(main_tf).read()
    passed = set(re.findall(r"^\s*(\w+)\s*=\s*var\.(\w+)\s*$", source, re.M))
    for name in sorted(b_inputs):
        if (name, name) not in passed:
            errors.append(
                f"input {name}: not passed as `{name} = var.{name}` in main.tf"
            )
    for name in sorted(b_outputs):
        if not re.search(
            rf"value\s*=\s*module\.pypi\.{name}\s*$",
            source + open("outputs.tf").read(),
            re.M,
        ):
            errors.append(
                f"output {name}: not `value = module.pypi.{name}` in outputs.tf"
            )

    for e in errors:
        print(f"ERROR {e}")
    print(
        f"{len(b_inputs)} inputs, {len(b_outputs)} outputs checked: "
        + ("OK" if not errors else f"{len(errors)} problem(s)")
    )
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(*sys.argv[1:4]))
