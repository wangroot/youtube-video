#!/bin/bash
# author: gfw-breaker

channel=$1
csv=videos.txt

server_port=80
index_page=index.html
nginx_dir=/usr/share/nginx/html
cwd=/root/youtube-video

ts=$(date "+%m%d%H%m")

# get IP
ip=$(/sbin/ifconfig eth0 | grep "inet addr" | sed -n 1p | cut -d':' -f2 | cut -d' ' -f1)
if [ -z $ip ]; then
	ip=$(/sbin/ifconfig eth0 | grep "broadcast" | awk '{print $2}')
fi


cd $cwd
youtube-dl -U
git pull

# data_server=
source config

wget http://gfw-breaker.win/videos/news/readme.txt -O news.txt
sed -n '2,4p' news.txt | tac > hot.txt

wget https://raw.githubusercontent.com/begood0513/goodnews/master/indexes/ABC.csv -O news.txt
sed -n '1,3p' news.txt | sed "s#https://www.ntdtv.com#http://$ip:8808#" \
	| sed "s#https://www.epochtimes.com#http://$ip:10080#" | tac > abc.csv


ogate=$(curl -sIL https://qie655.i.oqoor.cn/ | grep Location | awk '{print $2}')
# page
#ts=$(date '+%m%d%H')

if [ "$data_server" == "" ]; then
	data_server=$ip
fi

while read line; do
	folder=$(echo $line | cut -d'|' -f1)
	id=$(echo $line | cut -d'|' -f2)
	title=$(echo $line | cut -d'|' -f3)
	
	video_dir=$nginx_dir/$folder
	mkdir -p $video_dir; cd $video_dir
	vname=_$id
	if [ -f $vname.mp4 ]; then
		echo "$vname.mp4 exists"
	else
		youtube-dl -o "_%(id)s.%(ext)s" -f 18 -- $id
	fi

	if [ -f $vname.jpg ]; then
		echo "$vname.jpg exists"
	else
		wget https://img.youtube.com/vi/$id/hqdefault.jpg -O $vname.jpg
	fi

	sed -e "s/videoFile/$vname/g" -e "s/videoFolder/$folder/g" \
		-e "s/videoTitle/$title/g" -e "s/proxy_server_ip/$ip/g" -e "s/data_server/$data_server/g" \
		 /root/youtube-video/template.html > $video_dir/$vname.html 

	grep -- $id list.txt > /dev/null 2>&1
	
	if [ $? -eq 0 ]; then
		echo 'ok'	
	else
		touch list.txt
		cat list.txt > tmp
		echo "$id|$title" > list.txt	
		cat tmp >> list.txt
	fi

done < $csv


#channels=$(ls -l $nginx_dir | grep ^d | awk '{ print $9 }')

channels=$(cat /root/youtube-video/channels.csv | awk -F',' '{ print $3}')
echo $channels

for folder in $channels; do
	video_dir=$nginx_dir/$folder

	cd $video_dir

	oldItems=$(sed -n '81,$p' list.txt | cut -d'|' -f1)
	for old in $oldItems; do
		echo "deleting : _$old.mp4"
		rm _$old.mp4
		rm _$old.jpg
		rm _$old.html
	done

	sed -i '81,$d' list.txt
	
	cat > $index_page << EOF
<html>
<head>
<meta charset="utf-8" /> 
<meta name="referrer" content="unsafe-url">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
<style>
body {
	margin: 10px;
	line-height: 140%;
	background: #faf0e6;
}
a {
	text-decoration: none;
}
a:link {
  color: purple;
}
a:visited{
  color: #3366cc;
}
div {
	margin-top: 12px;
}
</style>
</head>
<body>
<b>
EOF

	sed "s/proxy_server_ip/$ip/g" /root/youtube-video/links.html \
		| grep -v "^#" | sed 's#^#<div>#g' | sed 's#$#</div>#g' >> $index_page

	while read abc; do
		link=$(echo $abc | cut -d',' -f1)
		title=$(echo $abc| cut -d',' -f2)
		echo "<div><a href='$link?fromvideos'>🔥 $title</a><br/></div>" >> $index_page
	done < /root/youtube-video/abc.csv	

	while read news; do
			id=$(echo $news | cut -d',' -f1)
			title=$(echo $news | cut -d',' -f2)
			echo "<div><a href='http://$ip:10000/videos/news/$id.html?ts=$ts'>📌 $title</a><br/></div>" >> $index_page
	done < /root/youtube-video/hot.txt	
	
	cat >> $index_page <<EOF
<div>🔥 视频新闻：<a href='http://$ip/radio.html'> 希望之声广播</a>&nbsp; |&nbsp; <a href='http://$ip:10000/videos/res2/djy-news/'>大纪元新闻</a>&nbsp; |&nbsp; <a href='http://$ip:10000/videos/res2/ntd-news/'> 新唐人新闻</a>&nbsp; |&nbsp; <a href='http://$ip:10000/videos/res2/mh-news/'>今日慧闻</a>&nbsp; |&nbsp; <a href='http://$ip:10000/videos/res2/truth/'>真相传媒</a></div>
<div><a href='http://$ip:11000/show.htm#ogHome'>网门免翻墙，一键浏览全球精粹资源</a>（目前网站后台出现故障，<a href="https://github.com/gfw-breaker/nogfw/">请下载手机应用程序</a>）</div>
<!--
<div style="color:red">部分视频无法正常播放，正尝试解决后台服务器问题，请朋友们耐心等候</div>
-->
<hr/>
EOF

	while read video; do
			id=$(echo $video | cut -d'|' -f1)
			title=$(echo $video | cut -d'|' -f2)
			echo "<div><a href='/$folder/_$id.html'>$title</a><br/></div>" >> $index_page
	done < list.txt
	echo "</b></body></html>" >> $index_page
done

# tv page
/root/youtube-video/tv.sh
/root/youtube-video/rank.sh


