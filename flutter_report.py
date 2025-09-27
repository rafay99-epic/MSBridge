import subprocess
import re
from collections import defaultdict
from pathlib import Path
from datetime import datetime

REPORTS_DIR = Path("reports")
REPORTS_DIR.mkdir(exist_ok=True)

INDEX_FILE = REPORTS_DIR / "index.md"
LATEST_FILE = REPORTS_DIR / "latest.md"

LINE_PATTERN = re.compile(
    r"^(?P<level>\w+)\s•\s(?P<message>.+?)\s•\s(?P<file>lib\/[^\:]+):(?P<line>\d+):(?P<col>\d+)\s•\s(?P<rule>\w+)"
)


def run_flutter_analyze():
    print("Running `flutter analyze` ...")
    result = subprocess.run(
        ["flutter", "analyze"], capture_output=True, text=True
    )
    if result.returncode not in (0, 1):
        raise RuntimeError(
            f"flutter analyze failed: {result.stderr.strip()}"
        )
    return result.stdout


def parse_analyze_output(output: str):
    issues = defaultdict(list)
    counts = defaultdict(int)

    for line in output.splitlines():
        match = LINE_PATTERN.match(line.strip())
        if match:
            data = match.groupdict()
            issues[data["file"]].append(data)
            counts[data["level"]] += 1

    return issues, counts


def generate_markdown(issues: dict, counts: dict, run_time: str):
    md = []
    md.append(f"# Flutter Analyze Report — {run_time}\n")
    md.append("> Generated automatically by script\n")

    if not issues:
        md.append("✅ No issues found!\n")
        return "\n".join(md)

    # summary
    md.append("### Summary\n")
    for level, count in counts.items():
        md.append(f"- **{level.capitalize()}s**: {count}")
    md.append("")

    # details per file
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


def update_index(report_file: Path, counts: dict, run_time: str):
    """Update central index file with new run info"""
    line = (
        f"- [{run_time}]({report_file.name}) "
        f"— Infos: {counts.get('info', 0)}, "
        f"Warnings: {counts.get('warning', 0)}, "
        f"Errors: {counts.get('error', 0)}"
    )

    if INDEX_FILE.exists():
        old = INDEX_FILE.read_text(encoding="utf-8").splitlines()
    else:
        old = ["# Flutter Analyze History\n"]

    # prepend newest run
    old.insert(1, line)
    INDEX_FILE.write_text("\n".join(old), encoding="utf-8")


def main():
    run_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

    output = run_flutter_analyze()
    issues, counts = parse_analyze_output(output)
    md = generate_markdown(issues, counts, run_time)

    report_file = REPORTS_DIR / f"flutter_analyze_{timestamp}.md"
    report_file.write_text(md, encoding="utf-8")

    # also copy to latest
    LATEST_FILE.write_text(md, encoding="utf-8")

    # update index
    update_index(report_file, counts, run_time)

    print(f"✅ Report saved: {report_file}")
    print(f"📌 Index updated: {INDEX_FILE}")
    print(f"✨ Latest report: {LATEST_FILE}")


if __name__ == "__main__":
    main()