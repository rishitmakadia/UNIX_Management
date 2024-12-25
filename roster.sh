#!/bin/bash

# File path for roster
ROSTER_CSV="roster.csv"

# Function to add flight details
add_flight_details() {
    EMP_ID="$1"

    if [ ! -f "$ROSTER_CSV" ]; then
        echo "EmpID,Flight From,Flight To,Flight Date,Flight Number" > "$ROSTER_CSV"
    fi

    FLIGHT_FROM=$(zenity --entry --title="Flight From" --text="Enter departure location:")
    [ $? -ne 0 ] && exit 1
    FLIGHT_TO=$(zenity --entry --title="Flight To" --text="Enter destination location:")
    [ $? -ne 0 ] && exit 1
    FLIGHT_DATE=$(zenity --calendar --title="Flight Date" --text="Select flight date:" --date-format="%Y-%m-%d")
    [ $? -ne 0 ] && exit 1
    FLIGHT_NUMBER=$(zenity --entry --title="Flight Number" --text="Enter flight number:")
    [ $? -ne 0 ] && exit 1

    echo "$EMP_ID,$FLIGHT_FROM,$FLIGHT_TO,$FLIGHT_DATE,$FLIGHT_NUMBER" >> "$ROSTER_CSV"
    zenity --info --title="Success" --text="Flight details added successfully!"
}

# Validate input argument
if [ -z "$1" ]; then
    zenity --error --title="Error" --text="EmpID is required to access roster!"
    exit 1
fi

EMP_ID="$1"

# Roster Management Menu
while true; do
    CHOICE=$(zenity --list --title="Roster Management for EmpID: $EMP_ID" \
        --column="Action" --width=400 --height=300 \
        "Add Flight Details" \
        "Exit")

    case $CHOICE in
        "Add Flight Details")
            add_flight_details "$EMP_ID"
            ;;
        "Exit")
            exit 0
            ;;
        *)
            zenity --error --title="Error" --text="Invalid choice! Try again."
            ;;
    esac
done

