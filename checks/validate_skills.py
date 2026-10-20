"""Check the skill package against the Agent Skills spec and the house writing rules.

Usage: python3 -I checks/validate_skills.py <package-root>
Exits 1 when any hard check fails. Prints sentence-per-line warnings for manual review.
"""
import pathlib
import re
import sys

NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
LINK_RE = re.compile(r"\]\(([^)]+)\)")
SENTENCE_BREAK_RE = re.compile(r"[a-z0-9`)\"'][.!?] +[A-Z`\"]")
ABBREVIATIONS = ("e.g.", "i.e.", "vs.", "etc.")


def frontmatter(text):
    if not text.startswith("---\n"):
        return None
    end = text.find("\n---\n", 4)
    if end == -1:
        return None
    fields = {}
    for line in text[4:end].splitlines():
        key, sep, value = line.partition(":")
        if sep and not line.startswith(" "):
            fields[key.strip()] = value.strip()
    return fields


def prose_lines(text):
    in_code = False
    for number, line in enumerate(text.splitlines(), 1):
        if line.lstrip().startswith("```"):
            in_code = not in_code
            continue
        if in_code or line.lstrip().startswith("|") or line.startswith("---") or ":" in line[:12] and line[:1].isalpha() and number < 6:
            continue
        yield number, line


def main(root):
    root = pathlib.Path(root)
    errors, warnings = [], []
    markdown = sorted(root.rglob("*.md"))
    for skill_md in sorted(root.glob("skills/*/SKILL.md")):
        fields = frontmatter(skill_md.read_text())
        directory = skill_md.parent.name
        if fields is None:
            errors.append(f"{skill_md}: missing frontmatter")
            continue
        name, description = fields.get("name", ""), fields.get("description", "")
        if name != directory:
            errors.append(f"{skill_md}: name {name!r} does not match directory {directory!r}")
        if not NAME_RE.match(name) or len(name) > 64:
            errors.append(f"{skill_md}: invalid name {name!r}")
        if not 1 <= len(description) <= 1024:
            errors.append(f"{skill_md}: description length {len(description)} outside 1..1024")
        unknown = set(fields) - {"name", "description", "license", "compatibility", "metadata", "allowed-tools"}
        if unknown:
            errors.append(f"{skill_md}: fields outside the spec {sorted(unknown)}")
        print(f"ok frontmatter {skill_md.relative_to(root)} name={name} description={len(description)} chars")
    for path in markdown:
        text = path.read_text()
        for dash in ("—", "–"):
            if dash in text:
                errors.append(f"{path}: contains {dash!r}")
        outside_code = "\n".join(line for _, line in prose_lines(text))
        for target in LINK_RE.findall(outside_code):
            if target.startswith(("http://", "https://", "#")):
                continue
            resolved = (path.parent / target.split("#")[0]).resolve()
            if not resolved.exists():
                errors.append(f"{path.relative_to(root)}: broken link {target}")
            else:
                print(f"ok link {path.relative_to(root)} -> {target}")
        if path.name == "todo.md":
            continue
        for number, line in prose_lines(text):
            probe = re.sub(r"^\s*(#+\s*)?\d+\.\s", "", line)
            for abbreviation in ABBREVIATIONS:
                probe = probe.replace(abbreviation, "")
            if SENTENCE_BREAK_RE.search(probe):
                warnings.append(f"{path.relative_to(root)}:{number}: {line.strip()[:110]}")
    for warning in warnings:
        print(f"warn two sentences on one line? {warning}")
    for error in errors:
        print(f"FAIL {error}")
    print(f"{len(errors)} errors, {len(warnings)} sentence-per-line warnings")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
