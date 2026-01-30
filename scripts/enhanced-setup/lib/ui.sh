#!/bin/bash
# EZ-Homelab Enhanced Setup Scripts - UI Library
# Dialog/whiptail helper functions for consistent user interface

# Detect available UI tool
if command_exists whiptail; then
    UI_TOOL="whiptail"
elif command_exists dialog; then
    UI_TOOL="dialog"
else
    echo "Error: Neither whiptail nor dialog is installed. Please install one of them."
    exit 1
fi

# UI configuration
UI_HEIGHT=20
UI_WIDTH=70
UI_TITLE="EZ-Homelab Setup"
UI_BACKTITLE="EZ-Homelab Enhanced Setup Scripts v1.0"

# Colors (for dialog)
if [[ "$UI_TOOL" == "dialog" ]]; then
    export DIALOGRC="$SCRIPT_DIR/lib/dialogrc"
fi

# =============================================================================
# BASIC UI FUNCTIONS
# =============================================================================

# Display a message box
ui_msgbox() {
    local text="$1"
    local height="${2:-$UI_HEIGHT}"
    local width="${3:-$UI_WIDTH}"

    "$UI_TOOL" --backtitle "$UI_BACKTITLE" --title "$UI_TITLE" \
               --msgbox "$text" "$height" "$width"
}

# Display a yes/no question
ui_yesno() {
    local text="$1"
    local height="${2:-$UI_HEIGHT}"
    local width="${3:-$UI_WIDTH}"

    "$UI_TOOL" --backtitle "$UI_BACKTITLE" --title "$UI_TITLE" \
               --yesno "$text" "$height" "$width"
}

# Get user input
ui_inputbox() {
    local text="$1"
    local default="${2:-}"
    local height="${3:-$UI_HEIGHT}"
    local width="${4:-$UI_WIDTH}"

    "$UI_TOOL" --backtitle "$UI_BACKTITLE" --title "$UI_TITLE" \
               --inputbox "$text" "$height" "$width" "$default" 2>&1
}

# Display a menu
ui_menu() {
    local text="$1"
    local height="${2:-$UI_HEIGHT}"
    local width="${3:-$UI_WIDTH}"
    shift 2

    local menu_items=("$@")
    local menu_height=$(( ${#menu_items[@]} / 2 ))

    "$UI_TOOL" --backtitle "$UI_BACKTITLE" --title "$UI_TITLE" \
               --menu "$text" "$height" "$width" "$menu_height" \
               "${menu_items[@]}" 2>&1
}

# Display a checklist
ui_checklist() {
    local text="$1"
    local height="${2:-$UI_HEIGHT}"
    local width="${3:-$UI_WIDTH}"
    shift 2

    local checklist_items=("$@")
    local list_height=$(( ${#checklist_items[@]} / 3 ))

    "$UI_TOOL" --backtitle "$UI_BACKTITLE" --title "$UI_TITLE" \
               --checklist "$text" "$height" "$width" "$list_height" \
               "${checklist_items[@]}" 2>&1
}

# Display a radiolist
ui_radiolist() {
    local text="$1"
    local height="${2:-$UI_HEIGHT}"
    local width="${3:-$UI_WIDTH}"
    shift 2

    local radiolist_items=("$@")
    local list_height=$(( ${#radiolist_items[@]} / 3 ))

    "$UI_TOOL" --backtitle "$UI_BACKTITLE" --title "$UI_TITLE" \
               --radiolist "$text" "$height" "$width" "$list_height" \
               "${radiolist_items[@]}" 2>&1
}

# Display progress gauge
ui_gauge() {
    local text="$1"
    local percent="${2:-0}"
    local height="${3:-$UI_HEIGHT}"
    local width="${4:-$UI_WIDTH}"

    {
        echo "$percent"
        echo "$text"
    } | "$UI_TOOL" --backtitle "$UI_BACKTITLE" --title "$UI_TITLE" \
                   --gauge "$text" "$height" "$width" 0
}

# =============================================================================
# ADVANCED UI FUNCTIONS
# =============================================================================

# Display progress with updating percentage
ui_progress() {
    local title="$1"
    local command="$2"
    local height="${3:-$UI_HEIGHT}"
    local width="${4:-$UI_WIDTH}"

    {
        eval "$command" | while IFS= read -r line; do
            # Try to extract percentage from output
            if [[ "$line" =~ ([0-9]+)% ]]; then
                echo "${BASH_REMATCH[1]}"
            fi
            echo "$line" >&2
        done
        echo "100"
    } 2>&1 | "$UI_TOOL" --backtitle "$UI_BACKTITLE" --title "$UI_TITLE" \
                         --gauge "$title" "$height" "$width" 0
}

# Display a form with multiple fields
ui_form() {
    local text="$1"
    local height="${2:-$UI_HEIGHT}"
    local width="${3:-$UI_WIDTH}"
    shift 2

    local form_items=("$@")
    local form_height=$(( ${#form_items[@]} / 2 ))

    "$UI_TOOL" --backtitle "$UI_BACKTITLE" --title "$UI_TITLE" \
               --form "$text" "$height" "$width" "$form_height" \
               "${form_items[@]}" 2>&1
}

# Display password input (hidden)
ui_password() {
    local text="$1"
    local height="${2:-$UI_HEIGHT}"
    local width="${3:-$UI_WIDTH}"

    "$UI_TOOL" --backtitle "$UI_BACKTITLE" --title "$UI_TITLE" \
               --passwordbox "$text" "$height" "$width" 2>&1
}

# =============================================================================
# EZ-HOMELAB SPECIFIC UI FUNCTIONS
# =============================================================================

# Display deployment type selection
ui_select_deployment_type() {
    local text="Select your deployment type:"
    local items=(
        "core" "Core Only" "off"
        "single" "Single Server (Core + Infrastructure + Services)" "on"
        "remote" "Remote Server (Infrastructure + Services only)" "off"
    )

    ui_radiolist "$text" "$UI_HEIGHT" "$UI_WIDTH" "${items[@]}"
}

# Display service selection checklist
ui_select_services() {
    local deployment_type="$1"
    local text="Select services to deploy:"
    local items=()

    case "$deployment_type" in
        "core")
            items=(
                "duckdns" "DuckDNS (Dynamic DNS)" "on"
                "traefik" "Traefik (Reverse Proxy)" "on"
                "authelia" "Authelia (SSO Authentication)" "on"
                "gluetun" "Gluetun (VPN Client)" "on"
                "sablier" "Sablier (Lazy Loading)" "on"
            )
            ;;
        "single")
            items=(
                "core" "Core Services" "on"
                "infrastructure" "Infrastructure (Dockge, Pi-hole)" "on"
                "dashboards" "Dashboards (Homepage, Homarr)" "on"
                "media" "Media Services (Plex, Jellyfin)" "off"
                "media-management" "Media Management (*arr services)" "off"
                "homeassistant" "Home Assistant Stack" "off"
                "productivity" "Productivity (Nextcloud, Gitea)" "off"
                "monitoring" "Monitoring (Grafana, Prometheus)" "off"
                "utilities" "Utilities (Duplicati, FreshRSS)" "off"
            )
            ;;
        "remote")
            items=(
                "infrastructure" "Infrastructure (Dockge, Pi-hole)" "on"
                "dashboards" "Dashboards (Homepage, Homarr)" "on"
                "media" "Media Services (Plex, Jellyfin)" "off"
                "media-management" "Media Management (*arr services)" "off"
                "homeassistant" "Home Assistant Stack" "off"
                "productivity" "Productivity (Nextcloud, Gitea)" "off"
                "monitoring" "Monitoring (Grafana, Prometheus)" "off"
                "utilities" "Utilities (Duplicati, FreshRSS)" "off"
            )
            ;;
    esac

    ui_checklist "$text" "$UI_HEIGHT" "$UI_WIDTH" "${items[@]}"
}

# Display environment configuration form
ui_configure_environment() {
    local text="Configure your environment:"
    local items=(
        "Domain" 1 1 "" 1 20 50 0
        "Timezone" 2 1 "America/New_York" 2 20 50 0
        "PUID" 3 1 "1000" 3 20 50 0
        "PGID" 4 1 "1000" 4 20 50 0
    )

    ui_form "$text" "$UI_HEIGHT" "$UI_WIDTH" "${items[@]}"
}

# Display confirmation dialog
ui_confirm_action() {
    local action="$1"
    local details="${2:-}"
    local text="Confirm $action?"

    if [[ -n "$details" ]]; then
        text="$text\n\n$details"
    fi

    ui_yesno "$text"
}

# Display error and offer retry
ui_error_retry() {
    local error="$1"
    local suggestion="${2:-}"

    local text="Error: $error"
    if [[ -n "$suggestion" ]]; then
        text="$text\n\nSuggestion: $suggestion"
    fi
    text="$text\n\nWould you like to retry?"

    ui_yesno "$text"
}

# Display success message
ui_success() {
    local message="$1"
    ui_msgbox "Success!\n\n$message"
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Check if UI is available (for non-interactive mode)
ui_available() {
    [[ -n "${DISPLAY:-}" ]] || [[ -n "${TERM:-}" ]] && [[ "$TERM" != "dumb" ]]
}

# Run command with UI progress if available
run_with_progress() {
    local title="$1"
    local command="$2"

    if ui_available; then
        ui_progress "$title" "$command"
    else
        print_info "$title"
        eval "$command"
    fi
}

# Display help text
ui_show_help() {
    local script_name="$1"
    local help_text="
EZ-Homelab $script_name

USAGE:
    $script_name [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Enable verbose logging
    -y, --yes           Assume yes for all prompts
    --no-ui             Run without interactive UI

EXAMPLES:
    $script_name                    # Interactive mode
    $script_name --no-ui           # Non-interactive mode
    $script_name --help            # Show help

For more information, visit:
https://github.com/your-repo/EZ-Homelab
"

    echo "$help_text" | ui_msgbox "Help - $script_name" 20 70
}