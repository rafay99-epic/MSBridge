import subprocess
import re
from collections import defaultdict
from pathlib import Path

OUTPUT_FILE = "flutter_analyze_report.md"

# Regex to parse flutter analyze output lines
LINE_PATTERN = re.compile(
    r"^(?P<level>\w+)\s•\s(?P<message>.+?)\s•\s(?P<file>lib\/[^\:]+):(?P<line>\d+):(?P<col>\d+)\s•\s(?P<rule>\w+)"
)


def run_flutter_analyze():
    """Run flutter analyze and return its stdout output"""
    print("Running `flutter analyze` ...")
    result = subprocess.run(
        ["flutter", "analyze"], capture_output=True, text=True
    )
    if result.returncode not in (0, 1):  # 0 = clean, 1 = issues
        raise RuntimeError(
            f"flutter analyze failed: {result.stderr.strip()}"
        )
    return result.stdout


def parse_analyze_output(output: str):
    """Parse flutter analyze output into structured dictionary."""
    issues = defaultdict(list)

    for line in output.splitlines():
        match = LINE_PATTERN.match(line.strip())
        if match:
            data = match.groupdict()
            issues[data["file"]].append(data)

    return issues


def generate_markdown(issues: dict):
    """Generate markdown report from issues dict."""
    md = []
    md.append("# Flutter Analyze Report\n")
    md.append("> Generated automatically by script\n")

    if not issues:
        md.append("✅ No issues found!\n")
        return "\n".join(md)

    for file, file_issues in issues.items():
        md.append(f"## {file}\n")
        for issue in file_issues:
            md.append(
                f"- **{issue['level'].capitalize()}**: "
                f"{issue['message']}  \n"
                f"  📍 Line {issue['line']}, Col {issue['col']}  "
                f"(_Rule: `{issue['rule']}`_)\n"
            )
        md.append("\n")

    return "\n".join(md)


def main():
    output = run_flutter_analyze()
    issues = parse_analyze_output(output)
    md = generate_markdown(issues)

    Path(OUTPUT_FILE).write_text(md, encoding="utf-8")
    print(f"✅ Report generated: {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
