#!/bin/bash

# File path for roster
ROSTER_CSV="roster.csv"

# Function to add flight details
add_flight_details() {
    EMP_ID=$(zenity --entry --title="Enter EmpID" --text="Enter EmpID:")
    [ $? -ne 0 ] && exit 1

    if [ ! -f "$ROSTER_CSV" ]; then
        echo "EmpID,Flight From,Flight To,Flight Date,Departure Time,Arrival Time,Airline,Pilot Rank" > "$ROSTER_CSV"
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
    AIRLINE=$(zenity --entry --title="Airline" --text="Enter airline name:")
    [ $? -ne 0 ] && exit 1

    PILOT_RANK=$(zenity --list --title="Select Pilot Rank" --text="Choose the pilot rank:" --column="Rank" "Junior Pilot" "Senior Pilot" "Captain" --multiple --separator=",")
    [ $? -ne 0 ] && exit 1

    echo "$EMP_ID,$FLIGHT_FROM,$FLIGHT_TO,$FLIGHT_DATE,$DEPARTURE_TIME,$ARRIVAL_TIME,$AIRLINE,$PILOT_RANK" >> "$ROSTER_CSV"
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

    # Display "From" and "To" details
    FROM_TO=$(echo "$FLIGHTS" | awk -F, '{printf "From: %s\nTo: %s\n\n", $2, $3}')
    zenity --text-info --title="Flight Routes for $EMP_ID" --width=400 --height=300 --filename=<(echo "$FROM_TO")

    # Display "Date," "Departure Time," "Arrival Time," "Airline," and "Pilot Rank"
    DETAILS=$(echo "$FLIGHTS" | awk -F, '{printf "Date: %s\nDeparture: %s\nArrival: %s\nAirline: %s\nPilot Rank: %s\n\n", $4, $5, $6, $7, $8}')
    zenity --text-info --title="Flight Timings for $EMP_ID" --width=500 --height=400 --filename=<(echo "$DETAILS")
}

# Validate input arguments
if [ "$1" == "display" ]; then
    display_flight_details
    exit 0
fi

add_flight_details
