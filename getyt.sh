#!/bin/bash

if [ $# -ne 1 ] ; then
	echo downyt.sh http://www.youtube.com/watch?v=IYnCazyra6k
	exit 1
fi

if ( ! which urlencode >/dev/null 2>&1 ) || ( ! which binreplace >/dev/null 2>&1 ) ; then
	echo urlencode and binreplace must be in PATH
	exit 1
fi

url1="$1";

rm -f /tmp/downyt.html
if ! wget -q -O /tmp/downyt.html "$url1" ; then
	echo wget "$url1" failed
	exit
fi

if ! grep -q '"fmt_url_map": "' /tmp/downyt.html ; then
	echo unexpected content of "$url1"
	exit
fi

if grep -q '<meta name="title" content="...*">' /tmp/downyt.html ; then
	title=`grep -m 1 '<meta name="title" content="...*">' /tmp/downyt.html | sed -e 's/">//g' -e 's/.*"//g'`
elif grep -q '<h1 >...*</h1>' /tmp/downyt.html ; then
	title=`grep -m 1 '<h1 >...*</h1>' /tmp/downyt.html | sed -e 's/<.h1>//g' -e 's/.*<h1 >//g'`
else
	title=`grep -m pageVideoId /tmp/downyt.html | sed -e "s/';//g" -e "s/.*'//g"`
fi
title=`echo "$title" | binreplace -r '&amp;' '&' -r '&quot;' '"' -r '&lt;' '<' -r '&gt;' '>'`
title=`echo "$title" | binreplace -r '&amp;' '&' -r '&quot;' '"' -r '&lt;' '<' -r '&gt;' '>'`
title=`echo "$title" | tr -d '\\\\/:*?"<>|'`

grep '"fmt_url_map": "' /tmp/downyt.html | binreplace -r ', ' '\n' | grep fmt_url_map | sed -e 's/"$//g' -e 's/.*"//g' | urldecode | tr ',' '\n' | sort -n -r | head -n 1 | sed -e 's/.*|//g' > /tmp/downyt.url
if ! grep -q '^http://' /tmp/downyt.url ; then
	echo unexpected content of fmt_url_map
	exit
fi

rm -f "$title.flv"
if ! wget -q -O "$title.flv" `cat /tmp/downyt.url` ; then
	echo wget flv failed
	exit 1
fi

rm /tmp/downyt.html /tmp/downyt.url 
