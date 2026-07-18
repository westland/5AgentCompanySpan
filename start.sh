#!/bin/bash
set -euo pipefail

export HOME=/app

# Configurations
OPENCLAW_HOME="${OPENCLAW_HOME:-/app/.openclaw}"
export OPENCLAW_CONFIG_PATH="${OPENCLAW_HOME}/openclaw.json"
PORTAL_REPORTS_URL="${PORTAL_REPORTS_URL:-http://127.0.0.1:7860/api/reports/submit}"
GEMINI_API_KEY="${GEMINI_API_KEY:-}"
OPENAI_API_KEY="${OPENAI_API_KEY:-}"
DISCORD_WEBHOOK_URL="${DISCORD_WEBHOOK_URL:-$PORTAL_REPORTS_URL}"

echo "Starting initialization of OpenClaw and Web Portal..."
echo "OPENCLAW_HOME is set to: $OPENCLAW_HOME"

# Phase 1: Set up directories
mkdir -p "${OPENCLAW_HOME}/logs"
mkdir -p "${OPENCLAW_HOME}/canvas"
mkdir -p "${OPENCLAW_HOME}/state"

for AGENT in henry coder scout writer watcher; do
    mkdir -p "${OPENCLAW_HOME}/workspace-${AGENT}/skills"
    mkdir -p "${OPENCLAW_HOME}/workspace-${AGENT}/memory"
    mkdir -p "${OPENCLAW_HOME}/agents/${AGENT}/sessions"
done

# Phase 2: Copy default workspaces
if [ -d "deploy/configs" ]; then
    for AGENT in henry coder scout writer watcher; do
        SRC="deploy/configs/workspace-${AGENT}"
        DEST="${OPENCLAW_HOME}/workspace-${AGENT}"
        if [ -d "$SRC" ]; then
            cp -r "$SRC"/* "$DEST/"
            echo "Copied workspace files for $AGENT"
        fi
    done
fi

# Substitute reports URL and IP into SOUL.md files
for AGENT in henry coder scout writer watcher; do
    SOUL="${OPENCLAW_HOME}/workspace-${AGENT}/SOUL.md"
    if [ -f "$SOUL" ]; then
        # Replace webhook placeholder
        sed -i "s|DISCORD_WEBHOOK_PLACEHOLDER|${PORTAL_REPORTS_URL}|g" "$SOUL"
        # Replace server IP
        sed -i "s|YOUR_SERVER_IP|127.0.0.1|g" "$SOUL"
    fi
done

# Determine audio capability based on OpenAI API key
if [ -n "$OPENAI_API_KEY" ]; then
    AUDIO_ENABLED="true"
else
    AUDIO_ENABLED="false"
fi

# Write openclaw.json config
cat > "${OPENCLAW_HOME}/openclaw.json" << CONFIGEOF
{
  "env": {
    "GEMINI_API_KEY": "${GEMINI_API_KEY}",
    "GOOGLE_API_KEY": "${GEMINI_API_KEY}",
    "OPENAI_API_KEY": "${OPENAI_API_KEY}",
    "PORTAL_REPORTS_URL": "${PORTAL_REPORTS_URL}",
    "DISCORD_WEBHOOK_URL": "${DISCORD_WEBHOOK_URL}"
  },
  "gateway": {
    "mode": "local",
    "http": {
      "endpoints": {
        "chatCompletions": {
          "enabled": true
        }
      }
    },
    "auth": {
      "mode": "none"
    }
  },
  "session": {},
  "acp": {
    "enabled": true,
    "allowedAgents": [
      "henry",
      "coder",
      "scout",
      "writer",
      "watcher"
    ],
    "maxConcurrentSessions": 5
  },
  "agents": {
    "defaults": {
      "timeoutSeconds": 300,
      "model": {
        "primary": "google/gemini-2.5-flash"
      },
      "subagents": {
        "allowAgents": [
          "scout",
          "writer",
          "coder",
          "watcher",
          "henry"
        ],
        "maxSpawnDepth": 1
      },
      "memorySearch": {
        "provider": "gemini",
        "fallback": "none",
        "remote": {
          "batch": {
            "enabled": false
          }
        }
      }
    },
    "list": [
      {
        "id": "henry",
        "name": "Henry",
        "default": true,
        "workspace": "${OPENCLAW_HOME}/workspace-henry",
        "agentDir": "${OPENCLAW_HOME}/agents/henry",
        "model": "google/gemini-2.5-flash"
      },
      {
        "id": "coder",
        "name": "Coder",
        "workspace": "${OPENCLAW_HOME}/workspace-coder",
        "agentDir": "${OPENCLAW_HOME}/agents/coder",
        "model": "google/gemini-2.5-flash"
      },
      {
        "id": "scout",
        "name": "Scout",
        "workspace": "${OPENCLAW_HOME}/workspace-scout",
        "agentDir": "${OPENCLAW_HOME}/agents/scout",
        "model": "google/gemini-2.5-flash"
      },
      {
        "id": "writer",
        "name": "Writer",
        "workspace": "${OPENCLAW_HOME}/workspace-writer",
        "agentDir": "${OPENCLAW_HOME}/agents/writer",
        "model": "google/gemini-2.5-flash"
      },
      {
        "id": "watcher",
        "name": "Watcher",
        "workspace": "${OPENCLAW_HOME}/workspace-watcher",
        "agentDir": "${OPENCLAW_HOME}/agents/watcher",
        "model": "google/gemini-2.5-flash"
      }
    ]
  },
  "models": {
    "providers": {
      "google": {
        "timeoutSeconds": 300,
        "baseUrl": "https://generativelanguage.googleapis.com/v1beta",
        "models": [
          "gemini-2.5-flash",
          "gemini-2.0-flash"
        ]
      }
    }
  },
  "channels": {},
  "bindings": [],
  "memory": {
    "backend": "builtin"
  },
  "logging": {
    "level": "info",
    "file": "${OPENCLAW_HOME}/logs/openclaw.log"
  },
  "cron": {
    "enabled": true
  },
  "tools": {
    "exec": {
      "security": "full",
      "ask": "off",
      "host": "gateway"
    },
    "elevated": {
      "enabled": true
    },
    "media": {
      "audio": {
        "enabled": ${AUDIO_ENABLED},
        "echoTranscript": true
      }
    },
    "message": {
      "crossContext": {
        "allowAcrossProviders": true
      }
    }
  },
  "approvals": {
    "exec": {
      "enabled": false
    }
  },
  "plugins": {
    "entries": {
      "google": {
        "enabled": true
      },
      "anthropic": {
        "enabled": false
      },
      "bonjour": {
        "enabled": false
      },
      "acpx": {
        "enabled": false
      },
      "browser": {
        "enabled": false
      },
      "device-pair": {
        "enabled": false
      },
      "phone-control": {
        "enabled": false
      },
      "talk-voice": {
        "enabled": false
      }
    }
  }
}
CONFIGEOF

# Write exec-approvals.json
cat > "${OPENCLAW_HOME}/exec-approvals.json" << EAEOF
{
  "version": 1,
  "socket": {
    "path": "${OPENCLAW_HOME}/exec-approvals.sock",
    "token": "$(openssl rand -hex 24 || echo 'dummytoken')"
  },
  "defaults": {
    "security": "full",
    "ask": "off"
  },
  "agents": {
    "*": {
      "security": "full",
      "ask": "off"
    }
  }
}
EAEOF

# Setup cron jobs
CRON_DIR="${OPENCLAW_HOME}/cron"
mkdir -p "${CRON_DIR}"
if [ -f "deploy/configs/jobs.json" ]; then
    cp "deploy/configs/jobs.json" "${CRON_DIR}/jobs.json"
else
    echo '{"version": 1, "jobs": []}' > "${CRON_DIR}/jobs.json"
fi
echo '{}' > "${CRON_DIR}/jobs-state.json"

# Fix config if needed
echo "Running openclaw doctor --fix..."
openclaw doctor --fix || true

# Start openclaw gateway in the background
echo "Starting OpenClaw Gateway..."
openclaw gateway run &

# Give it a few seconds to boot
sleep 3

# Run the portal server in the foreground
echo "Starting FastAPI Web Portal..."
cd portal
python -m uvicorn main:app --host 0.0.0.0 --port 7860
