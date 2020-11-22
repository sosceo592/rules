#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin; export PATH
########
# usage: bash <(curl -s https://raw.githubusercontent.com/mixool/shadowrocket-rules/main/generate.sh) category-porn
#######

# tempfile & rm it when exit
trap 'rm -f "$TMPFILE"' EXIT; TMPFILE=$(mktemp) || exit 1

function domainlist(){
    # 从v2fly/domain-list-community提取指定类别域名列表
    wget -qO- "https://raw.githubusercontent.com/v2fly/domain-list-community/master/data/$1" | grep -oE "^[a-zA-Z0-9./-].*" | sed -e "s/#.*//g" -e "s/@.*//g" >$TMPFILE
    includelistcn=$(cat $TMPFILE | grep -oE "include:.*" | cut -f2 -d: | tr "\n" " ") && sed -i -e "s/^include:.*//g" -e "s/^regexp:.*//g" -e "s/^full://g" -e "s/#.*//g" -e "s/@.*//g" $TMPFILE
    while [[ "$includelistcn" != "" ]]; do
        for list in $includelistcn; do
            wget -qO- "https://raw.githubusercontent.com/v2fly/domain-list-community/master/data/$list" | grep -oE "^[a-zA-Z0-9./-].*" | sed "s/#.*//g" >>$TMPFILE
        done
        includelistcn=$(cat $TMPFILE | grep -oE "include:.*" | cut -f2 -d: | tr "\n" " ") && sed -i -e "s/^include:.*//g" -e "s/^regexp:.*//g" -e "s/^full://g" -e "s/#.*//g" -e "s/@.*//g" $TMPFILE
    done
    cat $TMPFILE | sort -u | sed "s/[[:space:]]//g" |sed "/^$/d"
}

function allrocket(){
    # 屏蔽广告,大陆可访问直连(包含Apple和Google可在大陆访问的域名),不可访问走代理,未匹配走代理
    cat <<EOF >$TMPFILE
# Shadowrocket: $(date)
[General]
bypass-system = true
skip-proxy = 192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12, localhost, *.local, captive.apple.com
bypass-tun = 10.0.0.0/8,100.64.0.0/10,127.0.0.0/8,169.254.0.0/16,172.16.0.0/12,192.0.0.0/24,192.0.2.0/24,192.88.99.0/24,192.168.0.0/16,198.18.0.0/15,198.51.100.0/24,203.0.113.0/24,224.0.0.0/4,255.255.255.255/32
dns-server = system
ipv6 = false

[Rule]
# reject-list category-ads-all
$(wget -qO- https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/reject-list.txt | sed "s/^/DOMAIN-SUFFIX,&/" | sed 's/$/&,Reject/' | sed "s/DOMAIN-SUFFIX,regexp/URL-REGEX/")

# direct-list cn
$(wget -qO- https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/direct-list.txt | sed "s/^/DOMAIN-SUFFIX,&/" | sed "s/$/&,DIRECT/" | sed "s/DOMAIN-SUFFIX,regexp/URL-REGEX/")

# direct-list apple 
$(wget -qO- https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/apple-cn.txt | sed "s/^/DOMAIN-SUFFIX,&/" | sed "s/$/&,DIRECT/" | sed "s/DOMAIN-SUFFIX,regexp/URL-REGEX/")

# direct-list google 
$(wget -qO- https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/google-cn.txt | sed "s/^/DOMAIN-SUFFIX,&/" | sed "s/$/&,DIRECT/" | sed "s/DOMAIN-SUFFIX,regexp/URL-REGEX/")

# proxy-list 
$(wget -qO- https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/greatfire.txt  | sed "s/^/DOMAIN-SUFFIX,&/" | sed 's/$/&,PROXY/' | sed "s/DOMAIN-SUFFIX,regexp/URL-REGEX/")
$(wget -qO- https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/proxy-list.txt  | sed "s/^/DOMAIN-SUFFIX,&/" | sed 's/$/&,PROXY/' | sed "s/DOMAIN-SUFFIX,regexp/URL-REGEX/")

# IP-CIDR
IP-CIDR,192.168.0.0/16,DIRECT
IP-CIDR,10.0.0.0/8,DIRECT
IP-CIDR,172.16.0.0/12,DIRECT
IP-CIDR,127.0.0.0/8,DIRECT
IP-CIDR,91.108.4.0/22,PROXY,no-resolve
IP-CIDR,91.108.8.0/22,PROXY,no-resolve
IP-CIDR,91.108.12.0/22,PROXY,no-resolve
IP-CIDR,91.108.16.0/22,PROXY,no-resolve
IP-CIDR,91.108.56.0/22,PROXY,no-resolve
IP-CIDR,109.239.140.0/24,PROXY,PROXY
IP-CIDR,149.154.160.0/20,PROXY,no-resolve
IP-CIDR,2001:b28:f23d::/48,PROXY,no-resolve
IP-CIDR,2001:b28:f23f::/48,PROXY,no-resolve
IP-CIDR,2001:67c:4e8::/48,PROXY,no-resolve

# FINAL
GEOIP,CN,DIRECT
FINAL,PROXY

[Host]
localhost = 127.0.0.1

[URL Rewrite]
^http://(www.)?g.cn https://www.google.com 302
^http://(www.)?google.cn https://www.google.com 302
EOF

cat $TMPFILE
}

case $1 in
    allrocket)
        allrocket
        ;;
    *)
        domainlist $1
esac
