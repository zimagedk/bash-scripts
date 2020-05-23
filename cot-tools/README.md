
# Some tools for Cursor on Target testing


## sendcot
From the help:

````
This script sends cot events from a text file using either UDP or TCP
Each message can span over multiple lines in the file, but each event end-tag must be a the end of a line
socat must be installed for this script to work
Author: Morten Krogh Andersen / morten@zimage.dk
---
Usage: ./sendcot.sh options file

Options:
    -P --protocol [value]   transport protocol. Valid values: ucp or tcp. Default: udp
    -a --address            destination host/ip address
                            multicast transmission is possible by specifying a multicast address and udp as protocol
    -p --port [value]       destination port
    -i --interval [value]   the interval between message transmissions
                            default time unit is seconds, default value is 10. See 'sleep --help' for valid values
    -r --repeat             if specified, the script will keep running, sending the messages until stopped
    -h --help               show this help
````
