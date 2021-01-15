**whereAreMyFingers** faithfully tracks and compares usage of all keyboard devices and pointer devices as per the /dev/input files. It is fast, faithful, functional and it works.

## Requirements
The tool is compatible with UNIX-like systems. The code has been tested for bash, zsh and fish. It depends upon *xinput*, *killall*, *bc*; all other tools/ commands can be expected on a standard UNIX environment. There are certain ksh stuff used, but all such stuff is widely available and implemented in latest versions of other shells as well. The system would also need some nominal space to store the Logs.

## Usage
Clone this repo, cd into it, and make the scripts executable:
```
git clone git@github.com:GOSHROW/whereAreMyFingers.git
cd whereAreMyFingers
chmod +x StreamToBuffer.sh
chmod +x logViewer.sh
```
Access both the script files and amend them as suitable. See to it that the variables for action Logs path and the value for Buffer Switch Time remains consistent among both the files.

Add /file/path/to/StreamToBuffer.sh to Startup Applications, maybe in your **.xinitrc**. 

*i3 users can simply invoke this script file as* ```exec_always --no-startup-id /file/path/to/StreamToBuffer.sh``` *and then reload the i3 session*

For usage instructions on logViewer.sh, read up the man page provided. This script can be aliased into a more concise form as ```alias viewMyFingers='/file/path/to/logViewer.sh'```. Add the same to the .bashrc, .zshrc or whichever shell config file accordingly. 

An interesting use of this tool, will be by adding it accordingly to the status bar, conky or any customizable system monitor, by reading through *viewMyFingers* in fixed intervals.

i3blocks users can opt for a similar syntax to get Ratio of keyboard actions to pointer actions in last unit of Buffer Switch Time
```
[viewMyFingers]
command=sh /file/path/to/logViewer.sh 20
label=Fingers:
interval=120
color=#55FF66
```