#! /bin/sh -
# A demo implementation for reading the logs generated by StreamToBuffer

actionLog="./actionLogs.log"
bufferSwitchTime=30
# keep both consistent with that in StreamToBuffer

getLastNCompleteLogs() {
    local actionLogEndLine=`tail -1 $actionLog`
    while [ "$actionLogEndLine" != "EOA" ]; do
        sleep 0.2
        # echo "$actionLogEndLine"
        actionLogEndLine=`tail -1 $actionLog`
    done
    # Ensures that the Action Logs being read are complete in nature

    local N=`expr "$1" \* 3`
    # 3 lines of Pointer Action Log, Keyboard Action Log and EOA
    local outputFile="$2"
    echo "`tail -$N $actionLog`" >> $outputFile
}

getSeperatedNLogs() {
    # seperate out the File Contents for Pointer and Keyboard Logs, remove EOAs
    local joinedLogs="$1"
    local pointerLogs="$2"
    local keyboardLogs="$3"
    sed -n '1~3p' $joinedLogs > $pointerLogs
    sed -n '2~3p' $joinedLogs > $keyboardLogs
}

getCumulativeOverNLogs() {
    local N="$1"
    local outputFile="lastNCompleteLogs.log"
    if ! [ -s $actionLog ]; then 
        echo "whereAreMyFingers daemon does not log to provided file" >> Error.log
        exit 1
    fi
    # checks that the file is not empty / path is incorrect

    getLastNCompleteLogs $N $outputFile
    getSeperatedNLogs $outputFile PointerLogs.log KeyboardLogs.log
    rm $outputFile

    local PointerCount=0 KeyboardCount=0
    while IFS= read -r -u 4 PointerLog && IFS= read -r -u 5 KeyboardLog; do
        (( PointerCount+=PointerLog ))
        (( KeyboardCount+=KeyboardLog ))
    done 4<PointerLogs.log 5<KeyboardLogs.log
    rm PointerLogs.log KeyboardLogs.log
    
    echo "$PointerCount $KeyboardCount"
}

getAverageOverNLogs() {
    local N="$1"
    local cumulativeArrayOverNLogs=($(getCumulativeOverNLogs $N))
    local pointerCumulativeOverNLogs=${cumulativeArrayOverNLogs[0]}
    local keyboardCumulativeOverNLogs=${cumulativeArrayOverNLogs[1]}
    local pointerAverageOverNLogs=$( echo "scale=3; $pointerCumulativeOverNLogs / $N" | bc -l)
    local keyboardAverageOverNLogs=$( echo "scale=3; $keyboardCumulativeOverNLogs / $N" | bc -l)
    echo "$pointerAverageOverNLogs $keyboardAverageOverNLogs"
}

getRatio() {
    local N="$1"
    local numerator="$2"
    # distinguishes keyboard:pointer and pointer:keyboard
    # k and K are keyboard:pointer, other keys are the inverse
    local cumulativeArrayOverNLogs=($(getCumulativeOverNLogs $N))
    local pointerCumulativeOverNLogs=${cumulativeArrayOverNLogs[0]}
    local keyboardCumulativeOverNLogs=${cumulativeArrayOverNLogs[1]}
    if [ $numerator = "k" ] || [ $numerator = "K" ]; then
        echo "$(( keyboardCumulativeOverNLogs / pointerCumulativeOverNLogs))"
    else
        echo "$(( pointerCumulativeOverNLogs / keyboardCumulativeOverNLogs))"
    fi
}

timeToLogNumbers() {
    # provides the -time option
    timeParameter="$1"
    echo "$(( timeParameter / bufferSwitchTime ))"
}

# myFingersLog() {
#     # main function, gets the user input from STDIN

# }