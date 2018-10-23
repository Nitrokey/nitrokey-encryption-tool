#!/usr/bin/env bash

#set -x

plain=$1
if [ -z "$1" ]; then
    plain=$0
fi

encr=/tmp/encr
decr=/tmp/decr
kid=0

killall pcscd scdaemon
pcscd

pgrep -fla pcscd
if [ "$?" == "0" ]; then
	echo "Failed to run pcscd. Encryption/decryption might not work."
fi

python3 encryption_tool.py --verbose encrypt $plain $encr $kid
python3 encryption_tool.py --verbose --pin 123456 decrypt $encr $decr $kid

diff $plain $decr | head -3
diff <(xxd $plain) <(xxd $decr) | head -5
wc -l $plain $decr
ls -l $plain $decr
