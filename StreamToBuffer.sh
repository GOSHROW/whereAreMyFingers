#! /bin/sh -

getDevices() {
    # deviceIDArray=("${(@f)$(xinput list --id-only)}") 
    # Use the previous line for a simpler implementation in zsh

    xinput list --id-only >> DevicesList
    # bash 4.0+ could go for mapfile or readarray. 
    # For backward compatibility, read the file onto an array explicitly.
    local deviceIDArray=()
    while IFS= read -r line; do
        deviceIDArray+=("$line")
    done < DevicesList
    rm DevicesList
    echo ${deviceIDArray[*]}
}

getRedirectCommand() {
    # returns an to-be evaluated command which redirects xinput from Devices
    local deviceIDArray=$(getDevices)
    local redirectCommand=""
    for deviceID in ${deviceIDArray[@]}; do
        redirectCommand+="xinput test $deviceID >> myfile && "
    done
    if [ -z "$redirectCommand" ]; then 
        printf "No Devices found to be added to the Redirection Buffer"
    else
        echo $redirectCommand >> redirectCommandFile
        redirectCommand=$(rev redirectCommandFile | cut -c 4- | rev)
        rm redirectCommandFile
    fi
    echo $redirectCommand
}

getRedirectCommand