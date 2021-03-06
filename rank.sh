#!/bin/bash

baseDir=/usr/share/nginx/html
page=$baseDir/rank.html

start=$(head -n 1 /var/log/nginx/access.log | awk '{print $4" "$5}')
cdate=$(echo $start | cut -c2- | cut -d':' -f1 | sed 's#/#-#g')
echo $cdate

cd /root/youtube-video

grep '\.jpg' /var/log/nginx/access.log | awk '{ print $1, $7 }' | sort | uniq | grep '/_' | grep -v '/videos/' | cut -d'/' -f2 | sort  | uniq -c | sort -nr > vv.txt

cat > $page << EOF
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-s">
<style>
body {
	padding: 5px;
}
th, td {
    padding: 3px;
}
</style>
<b>
开始于： $start <br/>
观看量： total_count
</b><br/><br/>
<table border='1px' cellspacing='0'>
<tr><th>频道名称</th><th>观看量</th></tr>

EOF

total=0

while read line; do
	count=$(echo $line | awk '{ print $1 }')
	key=$(echo $line | awk '{ print $2 }')
	total=$(($total + $count))

	title=$(grep $key channels.csv | cut -d',' -f1)
	echo "<tr><td><a href='./$key' target='_blank' style='text-decoration:blink;'>$title</a></td><td style='text-align:right;'>$count</td></tr>" >> $page	
done < vv.txt

sed -i "s/total_count/$total/" $page

cpage=$(echo $page | sed "s/rank/$cdate/")

cp $page $cpage


