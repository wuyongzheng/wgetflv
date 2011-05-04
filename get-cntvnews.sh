#!/bin/bash

getcntv='/home/atp/app/wgetflv/getcntv.sh'

function cctvtxt {
	date=`wget -O - -q $url | dos2unix | grep dateurl.= | sed -e 's/.*= //g' -e 's/;.*//g'`
	if ! echo $date | grep -q '^........$' ; then
		echo ERR: $enname: cctvtxt: invalid date
		echo ERR: $enname: cctvtxt: invalid date >> get-cntvnews.log
		url=""
		return
	fi
	url2=`wget -O - -q "http://cctv.cntv.cn/lm/$enname/$date.shtml" | iconv -f gbk -t utf8 | dos2unix | grep new.title_array_01 | head -n 1 | sed -e 's/..;.*//g' -e 's/.*,.//g'`
}

function cctvimg {
	line=`wget -q -O - $url | iconv -f gbk -t utf8 | dos2unix | binreplace -d '\n' -r '<div' '\n<div' -r '</div>' '</div>\n' | grep '<div class="[ti][em].*http:.*/......../.......shtml' | sed -e 's/.*\(http:.*\/\(........\)\/\(......\).shtml\).*/\2\t\3\t\1/g' | sort -r -u | head -n 1`
	url2=`echo "$line" | cut -f 3`
	date=`echo "$line" | cut -f 1`
}

function bugu {
	line=`wget -O - -q $url | dos2unix | iconv -f gbk -t utf8 | grep item.itemnum....new.title_array | head -n 1`
	date1=`echo "$line" | sed -e 's/.*\(20[0-9][0-9]\)-\([0-1][0-9]\)-\([0-9][0-9]\)/\1\2\3/g' | cut -c -8`
	date2=`echo "$line" | sed -e 's/.*classpage.video.\(201.....\).*/\1/g'`
	url2=`echo "$line" | sed -e 's/shtml.,.*/shtml/g' -e 's/.*,.//g'`

	if echo "$date1" | grep -q '^201[0-9]*$' ; then
		date=$date1
	else
		date=$date2
	fi
}


if [ ! -f list.txt ] ; then
	echo cannot find list.txt
	exit
fi

until [ -e stop ] ; do
	ts1=`date +%s`

	for enname in `cut -f 1 list.txt` ; do
		getter=`grep "^$enname[[:space:]]" list.txt | cut -f 2`
		chname=`grep "^$enname[[:space:]]" list.txt | cut -f 3`
		url=`   grep "^$enname[[:space:]]" list.txt | cut -f 4`

		if ( echo $enname | grep -q '^#' ) || [ "x$url" = x ] ; then
			continue
		fi

		# getter reads $url and $enname
		#        sets $url2 and $date
		$getter
		if ! echo $url2 | grep -q '^http.*shtml$' ; then
			echo ERR: $enname: cctvtxt: cannot extract url
			echo ERR: $enname: cctvtxt: cannot extract url >> get-cntvnews.log
			continue
		fi
		if ! echo $date | grep -q '^201[0-9][0-9][0-9][0-9][0-9]$' ; then
			echo ERR: $enname: cctvimg: cannot extract date
			echo ERR: $enname: cctvimg: cannot extract date >> get-cntvnews.log
			continue
		fi

		odate=`ls | grep "^$chname-.........mkv" | tail -n 1 | sed -e 's/.*-//g' -e 's/.mkv//g'`
		if [ -n "$odate" ] ; then
			if [ $odate -ge $date ] ; then
				echo INF: $enname: up to date
				echo INF: $enname: up to date >> get-cntvnews.log
				continue
			fi
		fi

		cd /tmp/cctv
		env getcntv_sid=prefe1 bash $getcntv $url2 _prefetch_ >/dev/null 2>&1 &
		sleep 10
		if ! env getcntv_rate=50k getcntv_sid=video bash $getcntv $url2 $chname-$date.mkv ; then
			rm -f $chname-$date*
			env getcntv_sid=prefe2 bash $getcntv $url2 _prefetch_ >/dev/null 2>&1 &
		fi
		cd -
		if [ -f /tmp/cctv/$chname-$date.mkv ] ; then
			rm -f $chname-????????.mkv
			mv /tmp/cctv/$chname-$date.mkv ./
	
			echo `date '+%Y-%m-%d %H:%M:%S'` $chname-$date > /tmp/cctvlog.txt
			cat 下载记录.txt >> /tmp/cctvlog.txt
			mv /tmp/cctvlog.txt 下载记录.txt
			echo INF: $enname: downloading $chname-$date succeeded
			echo INF: $enname: downloading $chname-$date succeeded >> get-cntvnews.log
		else
			echo ERR: $enname: downloading $chname-$date failed
			echo ERR: $enname: downloading $chname-$date failed >> get-cntvnews.log
		fi
	done

	ts2=`date +%s`
	tss=`expr 14400 - $ts2 + $ts1`
	echo INF: sleeping for $tss seconds
	echo INF: sleeping for $tss seconds >> get-cntvnews.log
	sleep $tss >/dev/null 2>&1
done
