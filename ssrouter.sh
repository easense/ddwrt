#!/usr/bin/env sh
IPT14=/opt/sbin/iptables
IP_FILE=/opt/etc/chinadns_chnroute.txt
# 创建并应用代理规则
create_all_route(){
    # 创建 ipset 集合
    ipset -N china_routes hash:net maxelem 99999
    # 将国内 ip 段全部添加至集合中
    ( while read ip; do ipset add china_routes "$ip"; done ) < "$IP_FILE"
    # 创建 nat chain
    ${IPT14} -t nat -N SHADOWSOCKS
    # 过滤内网以及代理服务器通信流量
    ${IPT14} -t nat -A SHADOWSOCKS -d 192.168.0.0/16 -j RETURN
    ${IPT14} -t nat -A SHADOWSOCKS -d <你的代理服务器 ip> -j RETURN
    # 添加 ipset 集合规则（有比 iptables 一条条规则的添加和线性查找方式 速度更快优势）
    ${IPT14} -t nat -A SHADOWSOCKS -p tcp -m set --match-set china_routes dst -j RETURN
    # 规则之外的所有 ip 的 tcp 流量重定向到 1080 端口（ss 端口）
    ${IPT14} -t nat -A SHADOWSOCKS -p tcp -j REDIRECT --to-port 1080
    # 包括路由器本身流量
    ${IPT14} -t nat -A OUTPUT -p tcp -j SHADOWSOCKS
    # 应用规则
    ${IPT14} -t nat -A PREROUTING -p tcp -j SHADOWSOCKS
}
# 清空代理规则
clean_all_route(){
    ${IPT14} -t nat -D OUTPUT -p tcp -j SHADOWSOCKS
    ${IPT14} -t nat -F SHADOWSOCKS
    ${IPT14} -t nat -X SHADOWSOCKS
    ipset destroy china_routes
}
"$1"_all_route

