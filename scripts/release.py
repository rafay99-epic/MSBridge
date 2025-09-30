#!/usr/bin/env python3
import subprocess
import re
from datetime import datetime, date
from pathlib import Path
import os
import google.generativeai as genai

# -------------------
# CONFIG
# -------------------
APP_NAME = "MSBridge"
AUTHOR = {
    "name": "Abdul Rafay",
    "picture": "/assets/blog/authors/rafay.webp"
}
OG_IMAGE = "/assets/blog/org/msbridge.png"
COVER_BASE = "/assets/blog/post/"
APK_SRC = "build/app/outputs/flutter-apk/app-release.apk"

BLOG_DIR = "/Users/prometheus/Code/blog-starter-kit/_posts/"
DOWNLOADS_DIR = "/Users/prometheus/Code/blog-starter-kit/public/downloads/"
BASE_BRANCH = "main" 
PROJECT_ROOT = "/Users/prometheus/Code/blog-starter-kit"
CONSTANTS_FILE = os.path.join(PROJECT_ROOT, "src/lib/constants.ts")


# -------------------
# COLORS
# -------------------
class Colors:
    OKBLUE = "\033[94m"
    OKCYAN = "\033[96m"
    OKGREEN = "\033[92m"
    WARNING = "\033[93m"
    FAIL = "\033[91m"
    ENDC = "\033[0m"
    BOLD = "\033[1m"

def step(title): print(f"\n{Colors.OKBLUE}{Colors.BOLD}==> {title}{Colors.ENDC}")
def success(msg): print(f"{Colors.OKGREEN}✔ {msg}{Colors.ENDC}")
def info(msg): print(f"{Colors.OKCYAN}ℹ {msg}{Colors.ENDC}")
def warn(msg): print(f"{Colors.WARNING}⚠ {msg}{Colors.ENDC}")
def error(msg): print(f"{Colors.FAIL}✘ {msg}{Colors.ENDC}")

# -------------------
# HELPERS
# -------------------
def run_cmd(cmd):
    return subprocess.check_output(cmd, shell=True, text=True).strip()

def get_flutter_version():
    with open("pubspec.yaml", "r") as f:
        for line in f.readlines():
            if line.startswith("version:"):
                version = line.split(":")[1].strip().split("+")[0]
                return version
    return "0.0.0"

def format_version(version):
    parts = version.split(".")
    return f"V{parts[0]}-{parts[1]}"

def get_current_branch():
    return run_cmd("git rev-parse --abbrev-ref HEAD")

def get_git_commits(base_branch, current_branch):
    log = run_cmd(
        f'git log {base_branch}..{current_branch} --pretty=format:"%s"'
    )
    return [c.strip() for c in log.strip().split("\n") if c.strip()]

def clean_commit(msg):
    return re.sub(r"^[a-z]+(\(.*\))?:\s*", "", msg, flags=re.IGNORECASE)

# -------------------
# AI Release Notes Generator (Gemini 2.5 Pro)
# -------------------
def generate_ai_release_notes(version, commits):
    genai.configure(api_key=os.environ["GOOGLE_API_KEY"])
    model = genai.GenerativeModel("gemini-2.5-pro")

    commit_text = "\n".join(commits) if commits else "No specific commits."

    # Ask for both long blog post + short changelog
    prompt = f"""
    You are a release notes generator for MSBridge.

    Version: {version}
    Commits:
    {commit_text}

    Write TWO outputs:
    1. A short **changelog summary** (2–3 sentences, under 300 chars) that is suitable as a one-line feature description inside constants.ts.
      - It must highlight ONLY what's new in this version.
      - Avoid generic wording like "user-facing blog post" or "based on requirements".
      - Directly mention new features, fixes, and improvements.

    2. A detailed **blog post** with:
      - Engaging intro
      - "## Why this update?" (context/rationale)
      - "## What's New" (highlight features/improvements with bullets)
      - "## Fixes & Improvements" (if applicable)
      - Conclusion: encouraging users to upgrade
      - Conversational yet professional tone
    """

    response = model.generate_content(prompt)
    output = response.text.strip()

    parts = output.split("\n", 1)
    changelog = parts[0].strip().strip('"')
    blog_post = parts[1].strip() if len(parts) > 1 else ""

    return changelog, blog_post

# -------------------
# BLOG FILE CREATION
# -------------------
def create_blog_post(version, commits):
    slug = format_version(version)
    date_str = datetime.utcnow().isoformat() + "Z"
    cover_image = f"{COVER_BASE}{slug.lower()}.webp"

    info("Generating changelog + blog post with Gemini 2.5 Pro...")
    changelog, body = generate_ai_release_notes(version, commits)

    # YAML header
    header = f"""---
title: "MSBridge {version} Release"
excerpt: "{changelog}"
coverImage: "{cover_image}"
date: "{date_str}"
author:
  name: {AUTHOR['name']}
  picture: "{AUTHOR['picture']}"
ogImage:
  url: "{OG_IMAGE}"
---
"""

    md_content = header + "\n" + body
    md_path = Path(BLOG_DIR) / f"{slug}.md"
    with open(md_path, "w") as f:
        f.write(md_content)

    success(f"Blog post created at: {md_path}")
    return changelog  

# -------------------
# APK BUILD & MOVE
# -------------------
def build_and_move_apk(version):
    step("Building APK")
    run_cmd("flutter clean")
    run_cmd("flutter build apk --release")

    apk_src = Path(f"./{APK_SRC}")
    if not apk_src.exists():
        error("APK not found. Did flutter build fail?")
        raise FileNotFoundError("APK not found.")

    apk_name = f"ms-bridge-{version}.apk"
    apk_dest = Path(DOWNLOADS_DIR) / apk_name

    Path(DOWNLOADS_DIR).mkdir(parents=True, exist_ok=True)
    apk_src.replace(apk_dest)

    success(f"APK moved to {apk_dest}")
    return f"/downloads/{apk_name}"

# -------------------
# CONSTANTS FILE UPDATE
# -------------------
def update_constants_file(version, changelog, download_url):
    with open(CONSTANTS_FILE, "r") as f:
        content = f.read()

   
    last_build = max([int(num) for num in re.findall(r"buildNumber:\s*(\d+)", content)] or [0])
    build_number = last_build + 1
    today = date.today().isoformat()

    new_entry = f"""  {{
    version: "{version}",
    buildNumber: {build_number},
    releaseDate: "{today}",
    changelog:
      "{changelog}",
    downloadUrl: "{download_url}",
  }},"""

        
    pattern = r"(export const versions: AppVersion\[] = \[)"
    match = re.search(pattern, content)
    if not match:
        raise ValueError("Could not find versions array in constants.ts")

    insertion_point = match.end()
    new_content = content[:insertion_point] + "\n" + new_entry + content[insertion_point:]

    with open(CONSTANTS_FILE, "w") as f:
        f.write(new_content)

    success(f"constants.ts updated with version {version} (build {build_number})")

# -------------------
# MAIN
# -------------------
if __name__ == "__main__":
    step("Fetching version & branch")
    version = get_flutter_version()
    branch = get_current_branch()
    info(f"Version: {version}, Branch: {branch}")

    step("Collecting commits")
    commits = get_git_commits(BASE_BRANCH, branch)
    info(f"Found {len(commits)} commits unique to this branch")

    step("Generating blog post")
    excerpt = create_blog_post(version, commits)

    step("Building and exporting APK")
    download_url = build_and_move_apk(version)

    step("Updating constants.ts")
    update_constants_file(version, excerpt, download_url)

    step("🎉 Release complete")
    success(f"Version {version} packaged, blog + constants updated!")