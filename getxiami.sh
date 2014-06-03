#!/bin/bash

# require DeXiami.class in CWD; mid3v2

if [ $# -ne 1 ] ; then
	echo getxiami.sh 1769378719
	exit 1
fi

wget -q -O - "http://www.xiami.com/song/playlist/id/$1/object_name/default/object_id/0" > /tmp/xiami-song.xml

song_id=`grep "<song_id>" /tmp/xiami-song.xml | sed -e 's/<..CDATA.//g' -e 's/\]\]>//g' -e 'sx</.*xxg' -e 's/.*>//g'`
album_id=`grep "<album_id>" /tmp/xiami-song.xml | sed -e 's/<..CDATA.//g' -e 's/\]\]>//g' -e 'sx</.*xxg' -e 's/.*>//g'`
title=`grep "<title>" /tmp/xiami-song.xml | sed -e 's/<..CDATA.//g' -e 's/\]\]>//g' -e 'sx</.*xxg' -e 's/.*>//g'`
album_name=`grep "<album_name>" /tmp/xiami-song.xml | sed -e 's/<..CDATA.//g' -e 's/\]\]>//g' -e 'sx</.*xxg' -e 's/.*>//g'`
artist=`grep "<artist>" /tmp/xiami-song.xml | sed -e 's/<..CDATA.//g' -e 's/\]\]>//g' -e 'sx</.*xxg' -e 's/.*>//g'`
lyric=`grep "<lyric>" /tmp/xiami-song.xml | sed -e 's/<..CDATA.//g' -e 's/\]\]>//g' -e 'sx</.*xxg' -e 's/.*>//g'`
if [ -z "$song_id" ] ; then
	echo cannot figure out song_id
	exit 1
fi

location=`grep "<location>" /tmp/xiami-song.xml | sed -e 'sx</.*xxg' -e 's/.*>//g'`
url=`java DeXiami "$location"`
if [ -z "$url" ] ; then
	echo cannot java DeXiami "$location"
	exit 1
fi

rm -f $song_id.mp3
wget -O $song_id.mp3 $url
if [ -f $song_id.mp3 -a ! -s $song_id.mp3 ] ; then rm $song_id.mp3 ; fi
if [ -f $song_id.mp3 ] ; then
	mid3v2 "--artist=$artist" "--album=$album_name" "--song=$title" $song_id.mp3
fi
