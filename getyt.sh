#!/bin/bash

if [ $# -ne 1 -a $# -ne 2 ] ; then
	echo downyt.sh http://www.youtube.com/watch?v=IYnCazyra6k
	echo downyt.sh http://www.youtube.com/watch?v=IYnCazyra6k yihu-05
	exit 1
fi

# check http://en.wikipedia.org/wiki/YouTube for fmt description
fmtpri="38 37 22 18 35 34 5 45 43 17"

url1="$1";
if [ $# -eq 2 ] ; then
	title="$2"
fi

rm -f /tmp/downyt1.html
if ! wget -q -O /tmp/downyt1.html "$url1" ; then
	echo wget "$url1" failed
	exit
fi

if ! grep -q '"fmt_url_map": ".*videoplayback' /tmp/downyt1.html ; then
	echo unexpected content of "$url1"
	exit
fi

if [ -z "$title" ] ; then
	if grep -q '<meta name="title" content="...*">' /tmp/downyt1.html ; then
		title=`grep -m 1 '<meta name="title" content="...*">' /tmp/downyt1.html | sed -e 's/">//g' -e 's/.*"//g'`
	elif grep -q '<h1 >...*</h1>' /tmp/downyt1.html ; then
		title=`grep -m 1 '<h1 >...*</h1>' /tmp/downyt1.html | sed -e 's/<.h1>//g' -e 's/.*<h1 >//g'`
	elif grep -q pageVideoId /tmp/downyt1.html ; then
		title=`grep -m 1 pageVideoId /tmp/downyt1.html | sed -e "s/';//g" -e "s/.*'//g"`
	else
		echo cannot determine title. quit
		exit
	fi
	title=`echo "$title" | binreplace -r '&amp;' '&' -r '&quot;' '"' -r '&lt;' '<' -r '&gt;' '>'`
	title=`echo "$title" | binreplace -r '&amp;' '&' -r '&quot;' '"' -r '&lt;' '<' -r '&gt;' '>'`
	title=`echo "$title" | tr -d '\\\\/:*?"<>|'`
	echo "save to \"$title\""
fi

grep '"fmt_url_map": "' /tmp/downyt1.html | binreplace -r ',' '\n' -r '"' '\n' -r '\\/' '/' | grep videoplayback | cut -f 1,2 -d '|' > /tmp/downyt2.txt
if ! grep -q '^[1-9][0-9]*\|http://' /tmp/downyt2.txt ; then
	echo unexpected content of fmt_url_map
	exit
fi
for i in $fmtpri ; do grep "^$i.http" /tmp/downyt2.txt ; done | head -n 1 | cut -f '2' -d '|' > /tmp/downyt3.txt
if ! grep -q '^http://' /tmp/downyt3.txt ; then
	echo unexpected content of fmt_url_map ...
	exit
fi

rm -f "$title.mp4"
if ! wget --progress=dot:mega -O "$title.mp4" `cat /tmp/downyt3.txt` ; then
	echo wget mp4 failed
	exit 1
fi

rm /tmp/downyt1.html /tmp/downyt2.txt /tmp/downyt3.txt
