#!/bin/bash

# WiFi menu script for Sway with wofi

# Get list of available networks
networks=$(nmcli -t -f SSID device wifi list | grep -v '^$' | sort -u)

# Add options for WiFi management
options="📶 Refresh Networks
🔒 Connect to Hidden Network
📡 Toggle WiFi
⚙️  Network Settings
───────────────────
$networks"

# Show menu
selected=$(echo "$options" | wofi --dmenu --prompt "WiFi Networks:" --lines 15)

case "$selected" in
    "📶 Refresh Networks")
        nmcli device wifi rescan
        notify-send "WiFi" "Refreshing network list..."
        ;;
    "🔒 Connect to Hidden Network")
        ssid=$(wofi --dmenu --prompt "Network SSID:")
        if [ -n "$ssid" ]; then
            password=$(wofi --dmenu --password --prompt "Password:")
            if [ -n "$password" ]; then
                nmcli device wifi connect "$ssid" password "$password" hidden yes
            fi
        fi
        ;;
    "📡 Toggle WiFi")
        if nmcli radio wifi | grep -q enabled; then
            nmcli radio wifi off
            notify-send "WiFi" "WiFi disabled"
        else
            nmcli radio wifi on
            notify-send "WiFi" "WiFi enabled"
        fi
        ;;
    "⚙️  Network Settings")
        nm-connection-editor &
        ;;
    "───────────────────")
        # Separator, do nothing
        ;;
    *)
        if [ -n "$selected" ]; then
            # Check if network is already saved
            if nmcli connection show "$selected" >/dev/null 2>&1; then
                # Connect to saved network
                if nmcli connection up "$selected"; then
                    notify-send "WiFi" "Connected to $selected"
                else
                    notify-send "WiFi" "Failed to connect to $selected"
                fi
            else
                # Prompt for password
                password=$(wofi --dmenu --password --prompt "Password for $selected:")
                if [ -n "$password" ]; then
                    if nmcli device wifi connect "$selected" password "$password"; then
                        notify-send "WiFi" "Connected to $selected"
                    else
                        notify-send "WiFi" "Failed to connect to $selected"
                    fi
                fi
            fi
        fi
        ;;
esac
