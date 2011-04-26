#!/bin/bash

if [ $# -ne 1 ] ; then
	echo Usage: getalltudou.sh http://www.tudou.com/playlist/p/a65942.html
	exit
fi

while true ; do
	wget -O - -q $1 | iconv -f gbk -t utf8 | binreplace -d '\r' -d '\n' -r '{' '\n{' -r '}' '}\n' | grep '^.iid:' | sed -e 's/集.*//g' -e 's/.iid://g' -e 's/,.*第/ /g' | gawk '{printf("arr[%d]=%s\n", $2, $1);}' > /tmp/getalltudo-list.sh
	unset arr
	. /tmp/getalltudo-list.sh

	for i in ${!arr[@]} ; do
		j=`printf %02d $i`
		if [ -e $j.flv ] ; then
			continue
		fi
		bash /home/atp/app/wgetflv/gettudou.sh $1'?iid='${arr[$i]} $j
	done

	echo sleeping for 8 hours
	sleep 8h
done
