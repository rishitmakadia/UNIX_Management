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

# Function to delete personal details
delete_personal_details() {
    EMP_ID=$(zenity --entry --title="Delete Pilot" --text="Enter EmpID to delete:")
    [ $? -ne 0 ] && exit 1

    if [ ! -f "$PERSONAL_CSV" ]; then
        zenity --error --title="Error" --text="No personal data found!"
        return
    fi

    # Check if the EmpID exists
    if ! grep -q "^$EMP_ID," "$PERSONAL_CSV"; then
        zenity --info --title="No Details Found" --text="No details found for EmpID: $EMP_ID"
        return
    fi

    # Create a temporary file to store the updated data
    TEMP_FILE=$(mktemp)
    grep -v "^$EMP_ID," "$PERSONAL_CSV" > "$TEMP_FILE"
    mv "$TEMP_FILE" "$PERSONAL_CSV"

    zenity --info --title="Success" --text="Personal details for EmpID: $EMP_ID deleted successfully!"
}

# Function to display invoice
display_invoice() {
    EMP_ID=$(zenity --entry --title="Enter EmpID" --text="Enter EmpID:")
    [ $? -ne 0 ] && exit 1

    if [ ! -f "roster.csv" ]; then
        zenity --error --title="Error" --text="No flight roster data found!"
        return
    fi

    FLIGHTS=$(grep "^$EMP_ID," "roster.csv")
    if [ -z "$FLIGHTS" ]; then
        zenity --info --title="No Flights Found" --text="No flights found for EmpID: $EMP_ID"
        return
    fi

    TOTAL_HOURS=$(echo "$FLIGHTS" | awk -F, '{split($5, dep, ":"); split($6, arr, ":"); diff=((arr[1] - dep[1]) * 60 + (arr[2] - dep[2])) / 60; if (diff < 0) diff += 24; total += diff} END {print total}')
    
    # Determine pilot rank and corresponding bonus
    PILOT_RANK=$(echo "$FLIGHTS" | awk -F, '{print $8}' | head -n 1)
    case "$PILOT_RANK" in
        "Junior Pilot")
            BONUS_RATE=400
            ;;
        "Senior Pilot")
            BONUS_RATE=500
            ;;
        "Captain")
            BONUS_RATE=700
            ;;
        *)
            BONUS_RATE=0
            ;;
    esac

    HOURLY_RATE=1000
    GROSS_PAY=$(echo "$TOTAL_HOURS * $HOURLY_RATE + $TOTAL_HOURS * $BONUS_RATE" | bc)
    TAX=$(echo "$GROSS_PAY * 0.3" | bc)
    NET_PAY=$(echo "$GROSS_PAY - $TAX" | bc)

    INVOICE="EmpID: $EMP_ID\nTotal Flight Hours: $TOTAL_HOURS hours\nHourly Rate: ₹1000/hour\nBonus: ₹$((TOTAL_HOURS * BONUS_RATE))\nGross Pay: ₹$GROSS_PAY\nTax Deduction (30%): ₹$TAX\nTake-Home Pay: ₹$NET_PAY"
    zenity --text-info --title="Invoice for $EMP_ID" --width=600 --height=300 --filename=<(echo -e "$INVOICE")
}

# Main Menu
while true; do
    CHOICE=$(zenity --list --title="Pilot Management System" \
        --column="Action" --width=400 --height=400 \
        "Add Personal Details" \
        "Delete Pilot" \
        "Add Flight Roster" \
        "Display Flights for Pilot" \
        "Generate Invoice" \
        "Exit")

    case $CHOICE in
        "Add Personal Details")
            add_personal_details
            ;;
        "Delete Pilot Details")
            delete_personal_details
            ;;
        "Add Flight Roster")
            bash "$ROSTER_SCRIPT"
            ;;
        "Display Flights for Pilot")
            bash "$ROSTER_SCRIPT" display
            ;;
        "Generate Invoice")
            display_invoice
            ;;
        "Exit")
            exit 0
            ;;
        *)
            zenity --error --title="Error" --text="Invalid choice! Try again."
            ;;
    esac
done
