#!/bin/bash

# File path for roster
ROSTER_CSV="roster.csv"

# Function to add flight details
add_flight_details() {
    EMP_ID=$(zenity --entry --title="Enter EmpID" --text="Enter EmpID:")
    [ $? -ne 0 ] && exit 1

    if [ ! -f "$ROSTER_CSV" ]; then
        echo "EmpID,Flight From,Flight To,Flight Date,Departure Time,Arrival Time,Flight Number" > "$ROSTER_CSV"
    fi

    FLIGHT_FROM=$(zenity --entry --title="Flight From" --text="Enter departure location:")
    [ $? -ne 0 ] && exit 1
    FLIGHT_TO=$(zenity --entry --title="Flight To" --text="Enter destination location:")
    [ $? -ne 0 ] && exit 1
    FLIGHT_DATE=$(zenity --calendar --title="Flight Date" --text="Select flight date:" --date-format="%Y-%m-%d")
    [ $? -ne 0 ] && exit 1
    DEPARTURE_TIME=$(zenity --entry --title="Departure Time" --text="Enter departure time (HH:MM) in 24-hour format:")
    [ $? -ne 0 ] && exit 1
    ARRIVAL_TIME=$(zenity --entry --title="Arrival Time" --text="Enter arrival time (HH:MM) in 24-hour format:")
    [ $? -ne 0 ] && exit 1
    FLIGHT_NUMBER=$(zenity --entry --title="Flight Number" --text="Enter flight number:")
    [ $? -ne 0 ] && exit 1

    echo "$EMP_ID,$FLIGHT_FROM,$FLIGHT_TO,$FLIGHT_DATE,$DEPARTURE_TIME,$ARRIVAL_TIME,$FLIGHT_NUMBER" >> "$ROSTER_CSV"
    zenity --info --title="Success" --text="Flight details added successfully!"
}

# Function to display flight details
display_flight_details() {
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

    # Display flight details
    DETAILS=$(echo "$FLIGHTS" | awk -F, '{printf "From: %s\nTo: %s\nDate: %s\nDeparture: %s\nArrival: %s\nFlight Number: %s\n\n", $2, $3, $4, $5, $6, $7}')
    zenity --text-info --title="Flight Details for $EMP_ID" --width=500 --height=400 --filename=<(echo "$DETAILS")
}

# Validate input arguments
if [ "$1" == "display" ]; then
    display_flight_details
    exit 0
fi

add_flight_details
