import json
import sys
from pathlib import Path

target = Path(sys.argv[1])
template = Path(sys.argv[2])

incoming = json.loads(template.read_text())

if target.exists():
    data = json.loads(target.read_text())
else:
    data = {
        "$schema": incoming["$schema"],
        "imports": [],
        "mcpServers": {}
    }

data.setdefault("mcpServers", {})

if "dbhub" not in data["mcpServers"]:
    data["mcpServers"]["dbhub"] = incoming["mcpServers"]["dbhub"]

target.parent.mkdir(parents=True, exist_ok=True)
target.write_text(
    json.dumps(data, indent=2, ensure_ascii=False) + "\n"
)
