#!/usr/bin/env python3
"""Prepare an offline X-Agents handoff using its exported native policy.

This is a data exporter, NOT an approval service, JSON Schema implementation,
command runner or receipt verifier. X-Agents remains the authoritative validator.
"""
import argparse
import copy
import hashlib
import importlib
import json
import math
import re
import sys
from pathlib import Path, PurePosixPath

for _stream in (sys.stdout, sys.stderr):
    if hasattr(_stream, "reconfigure"):
        _stream.reconfigure(encoding="utf-8")

compiler = importlib.import_module("spec-compiler")
PROTOCOL = "xagents-template-handoff/1"
MAX_DOCUMENT_BYTES = 1024 * 1024


def canonical(value):
    """Deterministic ASCII JSON (valid UTF-8), not a signature or RFC 8785 JCS."""
    return json.dumps(value, sort_keys=True, ensure_ascii=True, separators=(",", ":"), allow_nan=False).encode("ascii")


def _pairs(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("duplicate JSON field")
        result[key] = value
    return result


def _constant(value):
    raise ValueError("nonfinite JSON number")


def _bounded_values(result):
    pending = [(result, 0)]
    while pending:
        value, depth = pending.pop()
        if depth > 64:
            raise ValueError("handoff document is too deeply nested")
        if isinstance(value, float) and not math.isfinite(value):
            raise ValueError("nonfinite JSON number")
        if isinstance(value, dict):
            pending.extend((item, depth + 1) for item in value.values())
        elif isinstance(value, list):
            pending.extend((item, depth + 1) for item in value)


def document(raw):
    if len(raw) > MAX_DOCUMENT_BYTES:
        raise ValueError("handoff document is too large")
    try:
        result = json.loads(raw.decode("utf-8"), object_pairs_hook=_pairs, parse_constant=_constant)
    except RecursionError as error:
        raise ValueError("handoff document is too deeply nested") from error
    _bounded_values(result)
    if not isinstance(result, dict):
        raise ValueError("handoff input must be a JSON object")
    return result


def _policy_revision(policy):
    fields = {"protocol", "source", "delivery_schema", "max_spec_bytes"}
    if not isinstance(policy, dict) or set(policy) != fields or policy["protocol"] != PROTOCOL:
        raise ValueError("unsupported consumer policy")
    source = policy["source"]
    if not isinstance(source, dict) or source.get("repository") != "seeker19110/projects-template":
        raise ValueError("unexpected adopted source")
    revision = source.get("revision")
    if not isinstance(revision, str) or re.fullmatch(r"[0-9a-f]{40}", revision) is None:
        raise ValueError("consumer policy must pin a reviewed source revision")
    schema = policy["delivery_schema"]
    if not isinstance(schema, dict) or schema.get("title") != "DeliveryContract":
        raise ValueError("missing native DeliveryContract schema")
    limit = policy["max_spec_bytes"]
    if type(limit) is not int or not 1 <= limit <= MAX_DOCUMENT_BYTES:
        raise ValueError("invalid consumer spec size limit")
    return revision


def read_spec(root, reference, limit):
    if not isinstance(reference, str) or not reference:
        raise ValueError("spec artifact_ref must be a relative file path")
    path = PurePosixPath(reference)
    if path.is_absolute() or ".." in path.parts or "\\" in reference or ":" in reference or str(path) != reference:
        raise ValueError("unsafe spec artifact_ref")
    base = root.resolve(strict=True)
    target = (base / reference).resolve(strict=True)
    target.relative_to(base)  # Reject symlink escapes and sibling-prefix paths.
    if not target.is_file():
        raise ValueError("spec artifact must be a regular file")
    with target.open("rb") as stream:
        raw = stream.read(limit + 1)
    if not raw or len(raw) > limit:
        raise ValueError("spec artifact is empty or too large")
    return raw


def _acceptance_entry(entry):
    if not isinstance(entry, dict) or set(entry) != {"acceptance_id", "test_ref"}:
        raise ValueError("invalid acceptance mapping")
    if any(not isinstance(value, str) or not value.strip() for value in entry.values()):
        raise ValueError("empty acceptance mapping")
    return entry["acceptance_id"]


def _acceptance_mapping(parsed, entries):
    required = {item for item in parsed["requirement_ids"] if item.startswith("AC-")}
    if not required or not isinstance(entries, list) or not entries:
        raise ValueError("explicit AC-to-test mapping is required")
    identifiers = [_acceptance_entry(entry) for entry in entries]
    if len(identifiers) != len(set(identifiers)) or set(identifiers) != required:
        raise ValueError("AC-to-test mapping must match every spec acceptance ID exactly once")


def _spec_claim(spec, parsed, raw):
    if not parsed["approved"] or not parsed["metadata"].get("Approver / date", "").strip():
        raise ValueError("spec must select Approved for implementation and name approver/date")
    for field in ("approved_by", "approved_at", "approval_record"):
        if not isinstance(spec.get(field), str) or not spec[field].strip():
            raise ValueError("structured approval claims are required; verification remains external")
    pins = {"state": "Approved for implementation", "artifact_sha256": hashlib.sha256(raw).hexdigest()}
    for field, expected in pins.items():
        if field in spec and spec[field] != expected:
            raise ValueError("existing spec pin conflicts with current bytes or selected state")
        spec[field] = expected


def build_handoff(root, plan, policy):
    """Prepare candidate data without granting authority or modifying caller inputs."""
    revision = _policy_revision(policy)
    if not isinstance(plan, dict) or not isinstance(plan.get("spec"), dict):
        raise ValueError("delivery plan must contain a structured spec")
    delivery = copy.deepcopy(plan)
    if delivery.get("source_revision", revision) != revision:
        raise ValueError("existing source pin conflicts with consumer policy")
    if delivery.get("blocking_decisions"):
        raise ValueError("blocking decisions must be resolved before handoff")
    spec = delivery["spec"]
    raw = read_spec(root, spec.get("artifact_ref"), policy["max_spec_bytes"])
    parsed = compiler.parse_spec_text(raw.decode("utf-8"), spec["artifact_ref"])
    _spec_claim(spec, parsed, raw)
    _acceptance_mapping(parsed, delivery.get("acceptance_tests"))
    delivery["source_revision"] = revision
    return {"protocol": PROTOCOL, "policy_sha256": hashlib.sha256(canonical(policy)).hexdigest(), "delivery": delivery}


def main(argv=None):
    parser = argparse.ArgumentParser(description="Prepare native delivery data; do not approve or execute it.")
    parser.add_argument("--root", required=True, type=Path, help="Project root containing the referenced spec")
    parser.add_argument("--policy", required=True, type=Path, help="Policy exported by the actual X-Agents consumer")
    parser.add_argument("--plan", required=True, type=Path, help="Explicit native delivery fields and approval claims")
    args = parser.parse_args(argv)
    try:
        with args.policy.open("rb") as stream:
            policy = document(stream.read(MAX_DOCUMENT_BYTES + 1))
        with args.plan.open("rb") as stream:
            plan = document(stream.read(MAX_DOCUMENT_BYTES + 1))
        result = build_handoff(args.root, plan, policy)
        print(canonical(result).decode("ascii"))
        return 0
    except (OSError, ValueError) as error:
        print("handoff: input rejected (%s); check policy, spec, approval claims and AC mapping" % type(error).__name__,
              file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
