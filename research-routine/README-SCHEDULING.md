# Harmonogram skanu (launchd, macOS)

Rutyna działa lokalnie (wymaga ai-knowledge na :3711 i zalogowanego `claude` CLI) — dlatego launchd, nie cloud.

## Instalacja (raz)

```bash
chmod +x ~/Projects/ai-tools/research-routine/run-research-scan.sh
cat > ~/Library/LaunchAgents/cc.lphouse.cfbench-research-scan.plist <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>cc.lphouse.cfbench-research-scan</string>
  <key>ProgramArguments</key><array>
    <string>/bin/bash</string>
    <string>/Users/lparfie/Projects/ai-tools/research-routine/run-research-scan.sh</string>
  </array>
  <key>StartCalendarInterval</key><dict>
    <key>Weekday</key><integer>1</integer>
    <key>Hour</key><integer>8</integer>
    <key>Minute</key><integer>57</integer>
  </dict>
  <key>StandardErrorPath</key><string>/tmp/cfbench-research-scan.err</string>
</dict></plist>
EOF
launchctl load ~/Library/LaunchAgents/cc.lphouse.cfbench-research-scan.plist
```

## Test ręczny

```bash
bash ~/Projects/ai-tools/research-routine/run-research-scan.sh
# raport: ~/Projects/ai-tools/research-reports/scan-YYYY-MM-DD.md
```

## Deinstalacja

```bash
launchctl unload ~/Library/LaunchAgents/cc.lphouse.cfbench-research-scan.plist
rm ~/Library/LaunchAgents/cc.lphouse.cfbench-research-scan.plist
```

Uwaga: laptop musi być włączony w poniedziałek 08:57; launchd NIE nadrabia pominiętych uruchomień
(StartCalendarInterval odpala pominięty job po wybudzeniu tylko gdy Mac spał, nie gdy był wyłączony).
Docelowo rutyna przechodzi do context-forge jako skill `/research-scan` — patrz
`~/Projects/ai-tools/context-forge-suggestions/001-research-scan-skill.md`.
