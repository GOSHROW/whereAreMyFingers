#! /bin/sh -

getDevices() {
    # deviceIDArray=("${(@f)$(xinput list --id-only)}") 
    # Use the previous line for a simpler implementation in zsh

    xinput list --id-only >> DevicesIDListFile
    # bash 4.0+ could go for mapfile or readarray. 
    # For backward compatibility, read the file onto an array explicitly.
    local deviceIDArray=()
    while IFS= read -r line; do
        deviceIDArray+=("$line")
        
    done < DevicesIDListFile
    rm DevicesIDListFile
    echo ${deviceIDArray[*]}
}

getRedirectCommand() {
    # returns an to-be evaluated command which redirects xinput from Devices
    local deviceIDArray=$(getDevices)
    local redirectCommand=""
    local BufferFile="$1"
    for deviceID in ${deviceIDArray[@]}; do
        redirectCommand+="xinput test $deviceID >> $BufferFile & "
    done
    if [ -z "$redirectCommand" ]; then 
        printf "No Devices found to be added to the Redirection Buffer"
    else
        echo $redirectCommand >> redirectCommandFile
        redirectCommand=$(rev redirectCommandFile | cut -c 3- | rev)
        rm redirectCommandFile
    fi
    echo $redirectCommand
}

initDeviceInputRedirect() {
    killall -q xinput
    # starts the process unaffected by previous run
    local redirectCommand=$(getRedirectCommand Buffer1)
    eval $redirectCommand
}


initDeviceInputRedirect