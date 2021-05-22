#!/bin/bash
export PATH="$PATH:/usr/local/bin/"
echo "Start to retrieving the cheapest 711 fuel price at $(date)"
fuelCheckDomain=$1
lowestStation=''
lowestPrice=999

if [[ -z $fuelCheckDomain ]] ; then
    fuelCheckDomain="https://fuelprice.io"
fi

function getFuelStations() {
    fuelStationsHtml=`curl "$fuelCheckDomain/brands/7-eleven/" -s`
    # exclude the stations in VIC
    fuelStationList=`echo $fuelStationsHtml | pup '#nearby-stations li:not(:contains("~")) a attr{href}' | uniq`
    echo $fuelStationList
}

function getFuelStationDetail() {
    fuelStationDetailHtml=`curl "$fuelCheckDomain$1" -s`
    fuelStationLink=`echo $fuelStationDetailHtml | pup '.station-bar .address a attr{href}' | sed -e 's/amp;//g'`
    echo $fuelStationLink
    fuelStationPrice=`echo $fuelStationDetailHtml | pup '.fuel_types #fuel_type-ulp91 strong text{}'`
    echo $fuelStationPrice
}

function fcomp() {
    awk -v n1="$1" -v n2="$2" 'BEGIN {if (n1+0<n2+0) exit 0; exit 1}'
}

fuelStationList=`getFuelStations`
# echo $fuelStationList
for station in $fuelStationList
do
    # echo $station
    fuelStationDetail=`getFuelStationDetail $station`
    fuelStationLink=`echo $fuelStationDetail | awk 'NR==1 {print $1}'`
    # echo $fuelStationLink
    fuelStationPrice=`echo $fuelStationDetail | awk 'NR==1 {print $2}'`
    # echo $fuelStationPrice
    if [[ -z $fuelStationPrice ]] ; then
        continue
    fi
    # do compare
    if fcomp "$fuelStationPrice" "$lowestPrice" ; then
        lowestStation=$fuelStationLink
        lowestPrice=$fuelStationPrice
        echo "711 petrol station is at $lowestStation with the lowest price $lowestPrice"
    fi
done
echo "Sending Notification Email"
echo -e "Subject:7-11 petrol station \n\n 711 petrol station is at $lowestStation with the lowest price $lowestPrice" | sendmail herakles86@gmail.com
echo "Finish at at $(date)"
