"""Tiện ích chung cho characterization test của 3 engine (tách từ test-engine-characterization.sh, W-05 2026-10-06).

Nạp engine theo đường dẫn file (tên có dấu gạch ngang nên không `import` thường được) và dựng repo giả trong thư mục tạm.
Không đổi hành vi test: các lớp test giữ nguyên thân, chỉ chuyển file.
"""
import importlib.util
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


def _load(name, filename):
    path = os.path.join(ROOT, "scripts", filename)
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def write(base, rel, text):
    full = os.path.join(base, rel.replace("/", os.sep))
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "w", encoding="utf-8") as fp:
        fp.write(text)
    return full
