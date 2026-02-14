#!/bin/sh
set -e

# --- Preflight checks ---
if [ -z "$ANTHROPIC_API_KEY" ]; then
  echo "FATAL: ANTHROPIC_API_KEY is not set." >&2
  echo "Add it in your Railway dashboard under Variables, then redeploy." >&2
  exit 1
fi

# Hardcoded paths for Railway persistent volume at /data.
export OPENCLAW_STATE_DIR="/data/.openclaw"
export OPENCLAW_WORKSPACE_DIR="/data/workspace"
export OPENCLAW_GATEWAY_TRUSTED_PROXIES="100.64.0.0/10"

# If a /data volume is mounted, fix its ownership so the non-root node
# user (uid 1000) can write to it.
if [ -d "/data" ]; then

  # Keep Go binaries and npm installs on the persistent volume
  export GOPATH="/data/go"
  export GOBIN="/data/go/bin"
  export PATH="/data/go/bin:/data/node_modules/.bin:${PATH}"
  mkdir -p /data/go/bin /data/node_modules /data/.blogwatcher 2>/dev/null || true

  # Symlink blogwatcher db dir so it persists across redeploys
  ln -sfn /data/.blogwatcher /home/node/.blogwatcher
fi

# Create state directory if it doesn't exist
mkdir -p "$OPENCLAW_STATE_DIR" 2>/dev/null || true

# Use Railway's PORT if set, otherwise default to 8080.
export OPENCLAW_GATEWAY_PORT="${PORT:-8080}"

# Seed a minimal config if none exists yet.
CONFIG_DIR="$OPENCLAW_STATE_DIR"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"
if [ ! -f "$CONFIG_FILE" ]; then
  mkdir -p "$CONFIG_DIR"
  cat > "$CONFIG_FILE" <<'CONF'
{
  "gateway": {
    "controlUi": {}
  },
  "plugins": {
    "entries": {
      "whatsapp": { "enabled": true }
    }
  }
}
CONF
fi

# --- Security hardening for persistent volume ---
if [ -d "/data" ]; then
  # Ensure ownership of the top-level /data directories
  chown 1000:1000 /data

  # Stratified permissions: sensitive dirs get owner-only, others stay accessible
  # Config, credentials, sessions — owner-only
  if [ -d "/data/.openclaw" ]; then
    chown -R 1000:1000 /data/.openclaw
    find /data/.openclaw -type d -exec chmod 700 {} +
    find /data/.openclaw -type f -exec chmod 600 {} +
  fi

  # Database — owner-only
  if [ -d "/data/.blogwatcher" ]; then
    chown -R 1000:1000 /data/.blogwatcher
    chmod 700 /data/.blogwatcher
    find /data/.blogwatcher -type f -exec chmod 600 {} + 2>/dev/null || true
  fi

  # Agent workspace — needs normal access
  if [ -d "/data/workspace" ]; then
    chown -R 1000:1000 /data/workspace
    find /data/workspace -type d -exec chmod 755 {} +
  fi

  # Go cache/source — readable, binaries executable
  if [ -d "/data/go" ]; then
    chown -R 1000:1000 /data/go
    find /data/go -type d -exec chmod 755 {} +
    find /data/go -type f -exec chmod 644 {} +
    # Executables in bin need execute permission
    if [ -d "/data/go/bin" ]; then
      find /data/go/bin -type f -exec chmod 755 {} +
    fi
  fi

  # npm packages
  if [ -d "/data/node_modules" ]; then
    chown -R 1000:1000 /data/node_modules
    find /data/node_modules -type d -exec chmod 755 {} +
  fi

  # --- Binary integrity verification ---
  MANIFEST="/data/.openclaw/.bin-manifest"

  verify_binaries() {
    _dir="$1"
    [ -d "$_dir" ] || return 0

    for _bin in "$_dir"/*; do
      [ -f "$_bin" ] || continue
      _hash=$(sha256sum "$_bin" | cut -d' ' -f1)
      _name=$(basename "$_bin")
      _expected=$(grep "^${_dir}/${_name} " "$MANIFEST" 2>/dev/null | cut -d' ' -f2)

      if [ -z "$_expected" ]; then
        # Unknown binary — new install, record it
        echo "entrypoint: new binary detected, adding to manifest: ${_dir}/${_name}" >&2
        echo "${_dir}/${_name} ${_hash}" >> "$MANIFEST"
      elif [ "$_hash" != "$_expected" ]; then
        # Hash mismatch — possible tampering
        echo "entrypoint: WARNING: binary hash mismatch for ${_dir}/${_name}, removing execute permission" >&2
        chmod -x "$_bin"
        # Update manifest with new hash (flagged)
        grep -v "^${_dir}/${_name} " "$MANIFEST" > "${MANIFEST}.tmp" 2>/dev/null || true
        echo "${_dir}/${_name} ${_hash} TAMPERED" >> "${MANIFEST}.tmp"
        mv "${MANIFEST}.tmp" "$MANIFEST"
      fi
    done
  }

  if [ ! -f "$MANIFEST" ]; then
    # First run: record hashes of all existing binaries
    touch "$MANIFEST"
    for _bindir in /data/go/bin /data/node_modules/.bin; do
      [ -d "$_bindir" ] || continue
      for _bin in "$_bindir"/*; do
        [ -f "$_bin" ] || continue
        _hash=$(sha256sum "$_bin" | cut -d' ' -f1)
        echo "${_bin} ${_hash}" >> "$MANIFEST"
      done
    done
    chmod 600 "$MANIFEST"
  else
    # Subsequent runs: verify binaries
    verify_binaries "/data/go/bin"
    verify_binaries "/data/node_modules/.bin"
    chmod 600 "$MANIFEST"
  fi

  # Explicit config file protection (belt-and-suspenders)
  [ -f "$CONFIG_FILE" ] && chmod 600 "$CONFIG_FILE"
fi

# All files created at runtime default to owner-only (600/700)
umask 077

# Drop to the non-root node user (uid 1000) for the actual process.
exec gosu node "$@"
