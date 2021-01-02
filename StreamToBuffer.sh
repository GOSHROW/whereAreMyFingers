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
    # Logs errors of xinput failing for master virtual devices or otherwise
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
        # need just two buffers to maintain concurrenct read and write
        newBufferName="Buffer${bufferNumber}"
        echo $newBufferName
        touch $newBufferName
        initDeviceInputRedirect $newBufferName & 
        sleep 1
        # ensures that previous bg function invocation has success
        # thus buffer is switched without losing any information in the moment
        # further loss of info may arise from failure of xinput to provide
        # then implement with watch on /dev/input events and mouse / mice
        if [ -n "$bufferName" ]; then
            getPointerActions $bufferName
            getKeyActions $bufferName
            rm $bufferName
        fi
        local bufferName=$newBufferName
        sleep 14
        # can suitably increase this to any feasible sleep time; needs testing
    done
    killall -q xinput
    rm Buffer*
}
# Test the bufferControld by `watch cat Buffer1` and `watch cat Buffer0`
# At this commit, other neccessary debug statements would go into the console

bufferControld

# After aborting the daemon, clean its zombies by `killall -q xinput`