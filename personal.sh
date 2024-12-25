#!/bin/bash

# File paths
PERSONAL_CSV="personal.csv"
ROSTER_SCRIPT="roster.sh"

# Function to generate EmpID
generate_emp_id() {
    local FIRST_LETTER=$(echo "$1" | head -c 1 | tr '[:lower:]' '[:upper:]')
    local LAST_LETTER=$(echo "$2" | head -c 1 | tr '[:lower:]' '[:upper:]')
    local PHONE_PREFIX=$(echo "$3" | head -c 3)
    echo "${FIRST_LETTER}${LAST_LETTER}${PHONE_PREFIX}"
}

# Function to add personal details
add_personal_details() {
    FIRST_NAME=$(zenity --entry --title="First Name" --text="Enter First Name:")
    [ $? -ne 0 ] && exit 1
    LAST_NAME=$(zenity --entry --title="Last Name" --text="Enter Last Name:")
    [ $? -ne 0 ] && exit 1
    PHONE=$(zenity --entry --title="Phone Number" --text="Enter Phone Number:")
    [ $? -ne 0 ] && exit 1

    # Generate EmpID
    EMP_ID=$(generate_emp_id "$FIRST_NAME" "$LAST_NAME" "$PHONE")

    # Create personal.csv if it doesn't exist
    if [ ! -f "$PERSONAL_CSV" ]; then
        echo "EmpID,First Name,Last Name,Phone" > "$PERSONAL_CSV"
    fi

    # Append details to personal.csv
    echo "$EMP_ID,$FIRST_NAME,$LAST_NAME,$PHONE" >> "$PERSONAL_CSV"
    zenity --info --title="Success" --text="Personal details added successfully! EmpID: $EMP_ID"
}

# Function to call roster script
add_flight_roster() {
    EMP_ID=$(zenity --entry --title="Enter EmpID" --text="Enter EmpID:")
    [ $? -ne 0 ] && exit 1

    # Pass EmpID to roster script
    bash "$ROSTER_SCRIPT" "$EMP_ID"
}

# Function to display flights for a particular pilot
display_flights() {
    EMP_ID=$(zenity --entry --title="Enter EmpID" --text="Enter EmpID:")
    [ $? -ne 0 ] && exit 1

    if [ ! -f "roster.csv" ]; then
        zenity --error --title="Error" --text="No flight roster data found!"
        return
    fi

    FLIGHTS=$(grep "^$EMP_ID," "roster.csv")
    if [ -z "$FLIGHTS" ]; then
        zenity --info --title="No Flights Found" --text="No flights found for EmpID: $EMP_ID"
    else
        FORMATTED_FLIGHTS=$(echo "$FLIGHTS" | awk -F, '{printf "Flight No: %s\nFrom: %s\nTo: %s\nDate: %s\n\n", $5, $2, $3, $4}')
        zenity --text-info --title="Flights for EmpID: $EMP_ID" --width=600 --height=400 --filename=<(echo "$FORMATTED_FLIGHTS")
    fi
}

# Function to display personal details
display_personal_details() {
    EMP_ID=$(zenity --entry --title="Enter EmpID" --text="Enter EmpID:")
    [ $? -ne 0 ] && exit 1

    if [ ! -f "$PERSONAL_CSV" ]; then
        zenity --error --title="Error" --text="No personal data found!"
        return
    fi

    DETAILS=$(grep "^$EMP_ID," "$PERSONAL_CSV")
    if [ -z "$DETAILS" ]; then
        zenity --info --title="No Details Found" --text="No details found for EmpID: $EMP_ID"
    else
        FORMATTED_DETAILS=$(echo "$DETAILS" | awk -F, '{printf "EmpID: %s\nFirst Name: %s\nLast Name: %s\nPhone: %s\n", $1, $2, $3, $4}')
        zenity --text-info --title="Personal Details for $EMP_ID" --width=600 --height=200 --filename=<(echo "$FORMATTED_DETAILS")
    fi
}

# Main Menu
while true; do
    CHOICE=$(zenity --list --title="Pilot Management System" \
        --column="Action" --width=400 --height=300 \
        "Add Personal Details" \
        "Add Flight Roster" \
        "Display Flights for Pilot" \
        "Display Personal Details" \
        "Exit")

    case $CHOICE in
        "Add Personal Details")
            add_personal_details
            ;;
        "Add Flight Roster")
            add_flight_roster
            ;;
        "Display Flights for Pilot")
            display_flights
            ;;
        "Display Personal Details")
            display_personal_details
            ;;
        "Exit")
            exit 0
            ;;
        *)
            zenity --error --title="Error" --text="Invalid choice! Try again."
            ;;
    esac
done

