# Scan scheduling (launchd, macOS)

The routine runs locally (it needs ai-knowledge on :3711 and a logged-in `claude` CLI) — hence
launchd rather than cloud.

## Install (once)

Run this from anywhere; `REPO` is the only thing to adjust if you cloned elsewhere.

```bash
REPO="$HOME/Projects/ai-tools"
chmod +x "$REPO/research-routine/run-research-scan.sh"
cat > ~/Library/LaunchAgents/cfbench-research-scan.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>cfbench-research-scan</string>
  <key>ProgramArguments</key><array>
    <string>/bin/bash</string>
    <string>$REPO/research-routine/run-research-scan.sh</string>
  </array>
  <key>StartCalendarInterval</key><dict>
    <key>Weekday</key><integer>1</integer>
    <key>Hour</key><integer>8</integer>
    <key>Minute</key><integer>57</integer>
  </dict>
  <key>StandardErrorPath</key><string>/tmp/cfbench-research-scan.err</string>
</dict></plist>
EOF
launchctl load ~/Library/LaunchAgents/cfbench-research-scan.plist
```

Note the unquoted heredoc: `$REPO` is expanded when the plist is written, because launchd does not
expand `~` or environment variables inside `ProgramArguments`.

## Manual test

```bash
bash research-routine/run-research-scan.sh
# report: research-reports/scan-YYYY-MM-DD.md
```

## Uninstall

```bash
launchctl unload ~/Library/LaunchAgents/cfbench-research-scan.plist
rm ~/Library/LaunchAgents/cfbench-research-scan.plist
```

Caveat: the laptop has to be awake on Monday at 08:57; launchd does NOT make up missed runs
(`StartCalendarInterval` fires a missed job after wake only if the Mac was asleep, not if it was off).
Eventually the routine moves into context-forge as a `/research-scan` skill — see
`context-forge-suggestions/001-research-scan-skill.md`.
