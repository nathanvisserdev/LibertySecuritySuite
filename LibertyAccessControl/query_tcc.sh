#!/bin/bash

# Helper script to query TCC database
# Usage: ./query_tcc.sh [user|system]

DB_TYPE="${1:-user}"

if [ "$DB_TYPE" = "user" ]; then
    DB_PATH="/Users/nathanvisser/Library/Application Support/com.apple.TCC/TCC.db"
else
    DB_PATH="/Library/Application Support/com.apple.TCC/TCC.db"
fi

# Stop TCC daemon
sudo launchctl unload /System/Library/LaunchDaemons/com.apple.tccd.plist 2>/dev/null

# Wait for daemon to stop
sleep 0.5

# Query the database
sqlite3 "$DB_PATH" "SELECT service, client, client_type, auth_value, auth_reason, auth_version, hex(csreq), policy_id, indirect_object_identifier_type, indirect_object_identifier, hex(indirect_object_code_identity), flags, last_modified, pid, pid_version, boot_uuid, last_reminded FROM access ORDER BY last_modified DESC"

# Restart TCC daemon
sudo launchctl load /System/Library/LaunchDaemons/com.apple.tccd.plist 2>/dev/null
