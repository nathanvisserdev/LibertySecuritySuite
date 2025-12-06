#!/bin/bash

# Script to query TCC database
# Usage: query_tcc.sh [user|system]

DB_TYPE="${1:-user}"

if [ "$DB_TYPE" = "system" ]; then
    DB_PATH="/Library/Application Support/com.apple.TCC/TCC.db"
else
    DB_PATH="$HOME/Library/Application Support/com.apple.TCC/TCC.db"
fi

# Prompt for sudo password using AppleScript for secure password entry
if ! sudo -n true 2>/dev/null; then
    PASSWORD=$(osascript -e 'Tell application "System Events" to display dialog "Administrator password is required to access the TCC database:" default answer "" with hidden answer' -e 'text returned of result' 2>/dev/null)
    if [ -z "$PASSWORD" ]; then
        echo "Error: Password prompt cancelled" >&2
        exit 1
    fi
    echo "$PASSWORD" | sudo -S true 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "Error: Invalid password" >&2
        exit 1
    fi
fi

# Stop tccd to release database lock
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.tccd.plist 2>/dev/null

# Query the database
# Output format: service|client|client_type|auth_value|auth_reason|auth_version|csreq(hex)|policy_id|indirect_object_identifier_type|indirect_object_identifier|indirect_object_code_identity|flags|last_modified|pid|pid_version|boot_uuid|last_reminded
sudo sqlite3 "$DB_PATH" "SELECT 
    service,
    client,
    client_type,
    auth_value,
    auth_reason,
    auth_version,
    COALESCE(hex(csreq), ''),
    COALESCE(policy_id, ''),
    COALESCE(indirect_object_identifier_type, ''),
    indirect_object_identifier,
    COALESCE(hex(indirect_object_code_identity), ''),
    COALESCE(flags, ''),
    last_modified,
    COALESCE(pid, ''),
    COALESCE(pid_version, ''),
    COALESCE(boot_uuid, ''),
    COALESCE(last_reminded, '')
FROM access;" 2>/dev/null

# Restart tccd
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.tccd.plist 2>/dev/null
