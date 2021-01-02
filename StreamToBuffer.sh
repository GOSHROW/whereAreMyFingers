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
    local InputBuffer="$1"
    for deviceID in ${deviceIDArray[@]}; do
        redirectCommand+="xinput test $deviceID >> $InputBuffer & "
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
    local InputBuffer="$1"
    local redirectCommand=$(getRedirectCommand $InputBuffer)
    eval $redirectCommand 2> DeviceError.log 
}

getPointerActions() {
    local InputBuffer="$1"
    local pointerMotionActionCount=$(grep -o 'motion' $InputBuffer | wc -l)
    # avoided motion coordinates as it isn't quantifiable aginst keystrokes
    local pointerButtonActionCount=$(grep -o 'button' $InputBuffer | wc -l)
    echo `expr $pointerMotionActionCount + $pointerButtonActionCount`
}

getKeyActions() {
    local InputBuffer="$1"
    local keyActionCount=$(grep -o 'press' $InputBuffer | wc -l)
    # Counting key release will only duplicate the effective keystrokes
    # Key release also may break concurrency of a keystroke on buffer change
    echo "$keyActionCount"
}

bufferControld() {
    local bufferNumber=0
    while true; do
        let bufferNumber=1-bufferNumber
        newBufferName="Buffer${bufferNumber}"
        echo $newBufferName
        touch $newBufferName
        initDeviceInputRedirect $newBufferName & 
        sleep 1
        if [ -n "$bufferName" ]; then
            getPointerActions $bufferName
            getKeyActions $bufferName
            rm $bufferName
        fi
        local bufferName=$newBufferName
        sleep 14
    done
    killall -q xinput
    rm Buffer*
}

bufferControld

# initDeviceInputRedirect buffer1 & 
# sleep 5
# getKeyActions buffer1
# getPointerActions buffer1
# sleep 5 
# getKeyActions buffer1
# getPointerActions buffer1

# rm buffer1
# sleep 5

# touch buffer1
# initDeviceInputRedirect buffer1 & 
# sleep 5
# getKeyActions buffer1
# getPointerActions buffer1 


# killall -q xinput