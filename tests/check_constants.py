#!/usr/bin/env python3
"""Keep VDB Engine string literals in the shared constants module."""

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "src"
CONSTANTS = SOURCE / "constants.vi"
TOKEN = re.compile(r'//[^\n]*|/\*[\s\S]*?\*/|"(?:\\[\s\S]|[^"\\])*"|"')
DECLARATION = re.compile(
    r'hàm công khai ([A-Z][A-Z0-9_]*)\(\)\s*\{\s*trả về '
    r'"(?:\\[\s\S]|[^"\\])*";\s*\};'
)


def main():
    errors = []
    names = set()
    for number, line in enumerate(CONSTANTS.read_text(encoding="utf-8").splitlines(), 1):
        line = line.strip()
        if not line or line.startswith("//"):
            continue
        match = DECLARATION.fullmatch(line)
        if not match:
            errors.append(f"src/constants.vi:{number}: expected a constant function")
            continue
        name = match.group(1)
        if name in names:
            errors.append(f"src/constants.vi:{number}: duplicate constant {name}")
        names.add(name)

    for path in sorted(SOURCE.rglob("*.vi")):
        if path == CONSTANTS:
            continue
        source = path.read_text(encoding="utf-8")
        for match in TOKEN.finditer(source):
            if match.group().startswith('"'):
                number = source.count("\n", 0, match.start()) + 1
                errors.append(f"{path.relative_to(ROOT)}:{number}: use src/constants.vi")

    if errors:
        raise SystemExit("\n".join(errors))
    print(f"VDB shared constants: PASS ({len(names)} functions)")


if __name__ == "__main__":
    main()
