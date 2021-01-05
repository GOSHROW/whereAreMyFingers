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
    echo $N
    local outputFile="$2"
    echo "`tail -$N $actionLog`" >> $outputFile
}

getLastNCompleteLogs 21 lastNCompleteLogs.log
