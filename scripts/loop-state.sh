#!/usr/bin/env bash
# loop-state.sh — Shell wrapper cho engine trạng thái vòng lặp /auto-complete (ADR-0012).

source "$(cd "$(dirname "$0")" && pwd)/_python-exec.sh" "loop-state" "$@"
