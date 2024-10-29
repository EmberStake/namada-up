#!/bin/bash

set -euo pipefail

# Check if NAMADA_LEDGER__CHAIN_ID is set
if [ -z "${NAMADA_LEDGER__CHAIN_ID:-}" ]; then
    echo "Error: NAMADA_LEDGER__CHAIN_ID environment variable is required"
    exit 1
fi

CONFIG_FILE="/home/pilot/.local/share/namada/$NAMADA_LEDGER__CHAIN_ID/config.toml"

TEMP_FILE=$(mktemp)

# Function to escape special characters in sed pattern
escape_sed() {
    echo "$1" | sed -e 's/[\/&]/\\&/g'
}

# Function to format array value
format_array() {
    local value=$1
    # Remove leading and trailing brackets if they exist
    value=${value#[}
    value=${value%]}

    # Split the string by commas and format each element
    local IFS=','
    local formatted_elements=()
    local result="["

    for element in $value; do
        # Trim whitespace
        element=$(echo "$element" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        # Remove existing quotes if they exist
        element=${element#\"}
        element=${element%\"}
        # Add quotes around the element
        formatted_elements+=("\"$element\"")
    done

    # Join elements with commas
    result+=$(IFS=', '; echo "${formatted_elements[*]}")
    result+="]"
    echo "$result"
}

# Function to determine if a value should be quoted
should_quote() {
    local value=$1
    # Check if it's an array
    if [[ $value == \[*\] ]]; then
        return 2  # Special return code for arrays
    # Only pure boolean, integer, or decimal numbers should be unquoted
    elif [[ $value =~ ^(true|false)$ ]] || \
         [[ $value =~ ^[0-9]+$ ]] || \
         [[ $value =~ ^[0-9]+\.[0-9]+$ ]]; then
        return 1
    else
        # Quote everything else, including time durations and mixed string-number formats
        return 0
    fi
}

# Function to process environment variables and update config
update_config() {
    # Check if config file exists
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Error: Config file not found at $CONFIG_FILE"
        return 1
    fi

    # Create a copy of the original config
    cp "$CONFIG_FILE" "$TEMP_FILE"

    # Process each environment variable that starts with NAMADA_
    env | grep '^NAMADA_' | while IFS='=' read -r key value; do
        # Skip empty values
        [ -z "$value" ] && continue

        # Remove NAMADA_ prefix
        config_key=${key#NAMADA_}

        # Convert environment variable format to TOML format
        # Replace __ with . and convert to lowercase
        toml_key=$(echo "$config_key" | sed 's/__/./g' | tr '[:upper:]' '[:lower:]')

        # Process value based on type
        should_quote "$value"
        quote_result=$?

        if [ $quote_result -eq 2 ]; then
            # Array type
            escaped_value=$(format_array "$value")
        elif [ $quote_result -eq 0 ]; then
            # String type
            escaped_value="\"$(escape_sed "$value")\""
        else
            # Numeric or boolean type
            escaped_value=$(escape_sed "$value")
        fi

        # For nested keys, construct the full path pattern
        if [[ $toml_key == *"."* ]]; then
            # Extract the section path and the final key
            section_path=$(echo "$toml_key" | sed 's/\.[^.]*$//')
            final_key=${toml_key##*.}

            # Check if the section exists
            if ! grep -q "^\[$section_path\]" "$TEMP_FILE"; then
                echo "Warning: Section [$section_path] not found in config file"
                continue
            fi

            # Use awk to precisely update the correct key in the correct section
            gawk -v section="[$section_path]" \
                -v key="$final_key" \
                -v value="$escaped_value" '
                BEGIN { in_section = 0; found = 0; }
                /^\[.*\]/ { in_section = ($0 == section) }
                in_section && !found && $0 ~ "^[[:space:]]*"key"[[:space:]]*=" {
                    print key " = " value
                    found = 1
                    next
                }
                { print }
            ' "$TEMP_FILE" > "$TEMP_FILE.tmp" && mv "$TEMP_FILE.tmp" "$TEMP_FILE"

            if [ "${PIPESTATUS[0]}" -ne 0 ]; then
                echo "Error: Failed to update key $toml_key"
                continue
            fi
        else
            # For top-level keys
            if grep -q "^[[:space:]]*$toml_key[[:space:]]*=" "$TEMP_FILE"; then
                sed -i "/^\[.*\]/!s/^\([[:space:]]*$toml_key[[:space:]]*=\)[[:space:]]*.*$/\1 $escaped_value/" "$TEMP_FILE"
            else
                echo "Warning: Key $toml_key not found in config file"
            fi
        fi
    done

    # Validate the new config file (basic syntax check)
    if command -v python3 >/dev/null 2>&1; then
        if ! python3 -c "import toml; toml.load('$TEMP_FILE')" 2>/dev/null; then
            echo "Error: Generated TOML is invalid, keeping original config"
            rm "$TEMP_FILE"
            return 1
        fi
    fi

    # Replace original with updated config
    mv "$TEMP_FILE" "$CONFIG_FILE"
    return 0
}

# Main execution
echo "Updating Namada configuration..."
if update_config; then
    echo "Configuration updated successfully"
else
    echo "Failed to update configuration"
    exit 1
fi

# Execute namada command with any additional arguments
exec namada "${@:1}"