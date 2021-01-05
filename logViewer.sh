#! /bin/sh -
# This is just a demo acting over the 

actionLog="./actionLogs.log"
# keep path consistent with that in StreamToBuffer

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

getCumulativeOverNLogs() {
    local N="$1"
    local outputFile="lastNCompleteLogs.log"
    if ! [ -s $actionLog ]; then 
        echo "whereAreMyFingers daemon does not log to provided file" >> Error.log
        exit 1
    fi
    # checks that the file is not empty / wrongly provided

    getLastNCompleteLogs $N $outputFile
    sed -n '1~3p' $outputFile > PointerLogs.log
    sed -n '2~3p' $outputFile > KeyboardLogs.log
    rm $outputFile
    # seperate out the File Contents for Pointer and Keyboard Logs, remove EOAs

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
    local CumulativeArrayOverNLogs=($(getCumulativeOverNLogs $N))
    local PointerCumulativeOverNLogs=${CumulativeArrayOverNLogs[0]}
    local KeyboardCumulativeOverNLogs=${CumulativeArrayOverNLogs[1]}
    local PointerAverageOverNLogs=$(( PointerCumulativeOverNLogs / N))
    local KeyboardAverageOverNLogs=$(( KeyboardCumulativeOverNLogs / N))
    echo "$PointerAverageOverNLogs $KeyboardAverageOverNLogs"
}

getAverageOverNLogs 3