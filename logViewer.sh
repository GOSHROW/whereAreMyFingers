#! /bin/sh -
# A working implementation for reading the logs generated by StreamToBuffer

actionLog="./actionLogs.log"
bufferSwitchTime=30
# keep both consistent with that in StreamToBuffer

getLastNCompleteLogs() {
    local N=`expr "$1" \* 3`
    # 3 lines of Pointer Action Log, Keyboard Action Log and EOA
    local outputFile="$2"

    local actionLogEndLine=`tail -1 $actionLog`
    while [ "$actionLogEndLine" != "EOA" ]; do
        sleep 0.2
        # echo "$actionLogEndLine"
        actionLogEndLine=`tail -1 $actionLog`
    done
    # Ensures that the Action Logs being read are complete in nature
    echo "`tail -$N $actionLog`" > $outputFile
    # tail will adjust for cases exceeding no of records 
}

getSeperatedNLogs() {
    # seperate out the File Contents for Pointer and Keyboard Logs, remove EOAs
    # this will NOT just seperate any log files, only its $joinedLogs
    local N="$1"
    local joinedLogs="lastNCompleteLogs.log"
    getLastNCompleteLogs $N $joinedLogs
    local pointerLogs="$2"
    local keyboardLogs="$3"
    sed -n '1~3p' $joinedLogs > $pointerLogs
    sed -n '2~3p' $joinedLogs > $keyboardLogs
    rm $joinedLogs
}

getCumulativeOverNLogs() {
    local N="$1"
    getSeperatedNLogs $N PointerLogs.log KeyboardLogs.log
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

getN() {
    # provides an option to extract to be independent of logging frequency
    local option="$1"
    local valueParameter="$2"
    declare N
    case $option in 
        "-T" | "--time")
            # the valueparameter now is assumed to have unit seconds
            N=$(( valueParameter / bufferSwitchTime ))
        ;;
        "-R" | "--record")
            # -R is assumed default as well in myFingersLog
            N=$valueParameter
        ;;
    esac
    echo "$N"
}

myFingersLog() {
    # main function, gets the user input from STDIN
    if ! [ -s $actionLog ]; then 
        echo "whereAreMyFingers daemon does not log to provided file" >> Error.log
        exit 1
    fi
    # checks that the file is not empty / path is incorrect

    local resultantView="$1"
    local completeLogsDefaultPath="lastNCompleteLogs.log"
    local pointerDefaultPath="PointerLogs.log"
    local keyboardDefaultPath="KeyboardLogs.log"
    case $resultantView in
        "-c" | "--complete")
        # case of getLastNCompleteLogs
            case $2 in
                "-T" | "--time" | "-R" | "--record")
                    Nparameter=($(getN $2 $3))
                    getLastNCompleteLogs $Nparameter $completeLogsDefaultPath
                ;;
                *)
                    if test $# -eq 2; then    
                        Nparameter=($(getN -R $2))
                        getLastNCompleteLogs $Nparameter $completeLogsDefaultPath
                    elif test $# -eq 3; then
                        completeLogsPath="$2"
                        Nparameter=($(getN -R $3))
                        getLastNCompleteLogs $Nparameter $completeLogsPath
                    else
                        completeLogsPath="$2"
                        Nparameter=($(getN $3 $4))
                        getLastNCompleteLogs $Nparameter $completeLogsPath
                    fi
                ;;
            esac
        ;;
        "-s" | "--seperated")
        # case of getting seperated logs
            case $2 in
                "-T" | "--time" | "-R" | "--record")
                    Nparameter=($(getN $2 $3))
                    getSeperatedNLogs $Nparameter $pointerDefaultPath $keyboardDefaultPath
                ;;
                *)
                    if test $# -eq 2; then    
                        Nparameter=($(getN -R $2))
                        getSeperatedNLogs $Nparameter $pointerDefaultPath $keyboardDefaultPath
                    elif test $# -eq 4; then
                        # exclusively either paths makes no sense
                        pointerPath="$2"
                        keyboardPath="$3"
                        Nparameter=($(getN -R $4))
                        getSeperatedNLogs $Nparameter $pointerPath $keyboardPath
                    else
                        pointerPath="$2"
                        keyboardPath="$3"
                        Nparameter=($(getN $4 $5))
                        getSeperatedNLogs $Nparameter $pointerPath $keyboardPath
                    fi
                ;;
            esac
        ;;
    esac
}
