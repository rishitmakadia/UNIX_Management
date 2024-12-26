#!/bin/bash

# File paths
PERSONAL_CSV="personal.csv"
ROSTER_SCRIPT="roster.sh"
ROSTER_CSV="roster.csv"

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
    
    AIRLINE=$(zenity --entry --title="Airline" --text="Enter Airline Name:")
    [ $? -ne 0 ] && exit 1
    
    DESIGNATION=$(zenity --list --title="Select Designation" --text="Choose the designation:" --column="Designation" \
        "Junior Pilot" "Senior Pilot" "Captain")
    [ $? -ne 0 ] && exit 1

    # Generate EmpID
    EMP_ID=$(generate_emp_id "$FIRST_NAME" "$LAST_NAME" "$PHONE")

    # Create personal.csv if it doesn't exist
    if [ ! -f "$PERSONAL_CSV" ]; then
        echo "EmpID,First Name,Last Name,Phone,Airline,Designation" > "$PERSONAL_CSV"
    fi

    # Append details to personal.csv
    echo "$EMP_ID,$FIRST_NAME,$LAST_NAME,$PHONE,$AIRLINE,$DESIGNATION" >> "$PERSONAL_CSV"
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

# Function to display personal information
display_personal_info() {
    EMP_ID=$(zenity --entry --title="Enter EmpID" --text="Enter EmpID:")
    [ $? -ne 0 ] && exit 1

    if [ ! -f "$PERSONAL_CSV" ]; then
        zenity --error --title="Error" --text="No personal data found!"
        return
    fi

    PERSONAL_DATA=$(grep "^$EMP_ID," "$PERSONAL_CSV")
    if [ -z "$PERSONAL_DATA" ]; then
        zenity --info --title="No Details Found" --text="No personal information found for EmpID: $EMP_ID"
        return
    fi

    HEADER=$(head -n 1 "$PERSONAL_CSV")
    DETAILS=$(echo "$PERSONAL_DATA" | awk -F, -v OFS="\n" '{for (i=1; i<=NF; i++) print $i}')
    FORMATTED_DETAILS=$(paste -d: <(echo "$HEADER" | awk -F, '{for (i=1; i<=NF; i++) print $i}') <(echo "$DETAILS"))

    zenity --text-info --title="Personal Info for $EMP_ID" --width=600 --height=400 --filename=<(echo "$FORMATTED_DETAILS")
}

# Function to calculate and display invoice
display_invoice() {
    EMP_ID=$(zenity --entry --title="Enter EmpID" --text="Enter EmpID:")
    [ $? -ne 0 ] && exit 1

    if [ ! -f "$ROSTER_CSV" ]; then
        zenity --error --title="Error" --text="No flight roster data found!"
        return
    fi

    FLIGHTS=$(grep "^$EMP_ID," "$ROSTER_CSV")
    if [ -z "$FLIGHTS" ]; then
        zenity --info --title="No Flights Found" --text="No flights found for EmpID: $EMP_ID"
        return
    fi

    TOTAL_HOURS=$(echo "$FLIGHTS" | awk -F, '{split($5, dep, ":"); split($6, arr, ":"); diff=((arr[1] - dep[1]) * 60 + (arr[2] - dep[2])) / 60; if (diff < 0) diff += 24; total += diff} END {print total}')

    PERSONAL_DATA=$(grep "^$EMP_ID," "$PERSONAL_CSV")
    DESIGNATION=$(echo "$PERSONAL_DATA" | awk -F, '{print $6}')

    case "$DESIGNATION" in
        "Junior Pilot")
            BONUS_RATE=400
            HOURLY_RATE=1100
            ;;
        "Senior Pilot")
            BONUS_RATE=500
            HOURLY_RATE=1800
            ;;
        "Captain")
            BONUS_RATE=700
            HOURLY_RATE=3000
            ;;
        *)
            BONUS_RATE=0
            HOURLY_RATE=0
            ;;
    esac

    GROSS_PAY=$(echo "$TOTAL_HOURS * $HOURLY_RATE + $TOTAL_HOURS * $BONUS_RATE" | bc)
    TAX=$(echo "$GROSS_PAY * 0.3" | bc)
    NET_PAY=$(echo "$GROSS_PAY - $TAX" | bc)

    INVOICE="EmpID: $EMP_ID\nTotal Flight Hours: $TOTAL_HOURS hours\nHourly Rate: ₹$HOURLY_RATE/hour\nBonus: ₹$(echo "$TOTAL_HOURS * $BONUS_RATE" | bc)\nGross Pay: ₹$GROSS_PAY\nTax Deduction (30%): ₹$TAX\nTake-Home Pay: ₹$NET_PAY"
    zenity --text-info --title="Invoice for $EMP_ID" --width=600 --height=400 --filename=<(echo -e "$INVOICE")
}

# Main Menu
while true; do
    CHOICE=$(zenity --list --title="Pilot Management System" \
        --column="Action" --width=400 --height=400 \
        "Add Personal Details" \
        "Display Personal Info" \
        "Add Flight Roster" \
        "Display Flights for Pilot" \
        "Generate Invoice" \
        "Delete Pilot Details" \
        "Exit")

    case $CHOICE in
        "Add Personal Details")
            add_personal_details
            ;;
        "Display Personal Info")
            display_personal_info
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
        "Delete Pilot Details")
            delete_personal_details
            ;;
        "Exit")
            exit 0
            ;;
        *)
            zenity --error --title="Error" --text="Invalid choice! Try again."
            ;;
    esac
done
