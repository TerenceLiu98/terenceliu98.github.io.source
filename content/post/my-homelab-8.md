---
title: "🧑🏿‍💻 Homelab: Cloudflare is All your Need, or Not"
date: 2024-09-19T00:11:21+08:00
draft: false
tags: ['homelab','oauth2-proxy', 'nginx-ingress-controller', 'GeoDNS', 'Authoritative DNS', '安全', '零信任', '存储', '权威 DNS']
series: ['homelab']
ads: true
---

回到原点，又开始了一年一度的 Homelab 折腾。这一次， 打算整点「起夜」级方案 :) 

在上一篇文章中提及了一些网络相关的方案，比如如何使用 Cloudflare Tunnel 进行“自建服务全球加速”。其中，也提及了可以自建 GeoDNS 达到类似的效果，在这里，我将详细描述各种方案的实践细节。

<!--more-->

## 自建 GeoDNS 以摆脱 Cloudflare 垄断

GeoDNS 是一种基于请求位置的流量分配过程，通过判断请求 IP 的地理位置，分配离他最近的出口 IP 以达到基于地理路由的流量优化。说人话就是各个大洲分别一个 IP。但是问题来了，谁会提供这种看起来就很好的服务呢？赛博菩萨表示，我们 Anycast 起家，天然无法提供 GeoDNS。因为对于 Anycast DNS 来说，他们会将一个 IP 通过 BGP 的方式在多地宣告，那么对于用户来说，能否到达离他们最近的 IP 就取决于本地网络提供商的接入情况和介入情况。一个简单的例子：如果当地网络服务商基于一些原因（例如安全和内容合规等原因）将 CDN 提供商的 IP 段进行路由级别的劣化，则无论 CDN 提供商多么的努力，也无法达到加速的目的。从计算机网络来说，Anycast 的实现是在网络层，而 GeoDNS 是在应用层，所以 Anycast 不知道请求者的 IP 位置，所以会出现这样的情况：虽然在 DNS 看来这个请求更加接近某地的服务器，但实际上这个 CDN 站点离原站更远。

基于以上的几点，我选择搭建 GeoDNS 来替代 Cloudflare 的 Anycast[^1]。

### 权威 DNS 的安装与配置（Authoritative DNS）

#### 前提

现存有不少开源权威 DNS 软件可以选择，比如 Bind9/PowerDNS 等等，我这里选择使用 PowerDNS，原因是因为他有 pdns-admin 可以让我进行 web 管理，而不是面对各种配置文件， 同时它是使用数据库进行 DNS 纪录存储，而不是跟 BIND9 一样的文本存储，更加适合高可用。因为涉及到高可用，首先我们需要准备两台 VPS，我选择了一台香港的服务器和一台纽约的服务器作为 ns1 和 ns2。同时，除了需要使用的域名，我们还需要一个额外的域名分配给 DNS 服务器，所以，基础准备如下[^2]：

| 域名 | IPV4 | IPV6 |
| --- | ---- | ---- |
| ns1.example.dns | 191.103.113.114 | 79cc:5f8f:47b1:963e:d248:70ea:0186:b842 | 
| ns2.example.dns | 31.84.179.51 | 9c7d:f2b6:1777:1904:fcfc:3a24:cccd:c0a6 |
| www.example.com | 249.209.110.226,160.38.17.187,66.167.146.39 | NULL |

在搭建权威 DNS 服务器的使用，我们常常听说一个词叫做胶水纪录 - Glue Record，这个纪录也是一种 DNS 纪录，但是保存在域名注册局的 DNS 服务器上，例如查询 `www.example.com` 的 纪录时，这个请求首先去到递归 DNS 服务器 `R`， 然后 `R` 再去询问对应的 DNS 根服务器 `A0`， 当然，`A0` 并不存放所有的纪录，他只会告诉 `R` 对应的域名 `example.com` 应该去对应的权威服务器 `A1` 进行查询。 所以，胶水纪录实际上就是 `A0` 到 `A1` 的指向。而所有的根服务器都可以到 [IANA](https://www.iana.org/domains/root/servers) 查到， 当然，我们也可以直接用 `dig` 查到：

```shell
(base) {} ~ dig com. NS + short
;; Invalid option

; <<>> DiG 9.10.6 <<>> com. NS + short
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 25108
;; flags: qr rd ra; QUERY: 1, ANSWER: 13, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1220
;; QUESTION SECTION:
;com.				IN	NS

;; ANSWER SECTION:
com.			35830	IN	NS	h.gtld-servers.net.
com.			35830	IN	NS	f.gtld-servers.net.
com.			35830	IN	NS	k.gtld-servers.net.
com.			35830	IN	NS	b.gtld-servers.net.
com.			35830	IN	NS	c.gtld-servers.net.
com.			35830	IN	NS	g.gtld-servers.net.
com.			35830	IN	NS	d.gtld-servers.net.
com.			35830	IN	NS	m.gtld-servers.net.
com.			35830	IN	NS	a.gtld-servers.net.
com.			35830	IN	NS	j.gtld-servers.net.
com.			35830	IN	NS	e.gtld-servers.net.
com.			35830	IN	NS	i.gtld-servers.net.
com.			35830	IN	NS	l.gtld-servers.net.

;; Query time: 15 msec
;; SERVER: 192.168.1.1#53(192.168.1.1)
;; WHEN: Thu Sep 26 13:43:28 IST 2024
;; MSG SIZE  rcvd: 256

;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 48582
;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;short.				IN	A

;; Query time: 5 msec
;; SERVER: 192.168.1.1#53(192.168.1.1)
;; WHEN: Thu Sep 26 13:43:28 IST 2024
;; MSG SIZE  rcvd: 34
```

我们可以看到 `.com`这个域名是在 `a.gtld-servers.net.` 到 `l.gtld-servers.net.` 这些 DNS 根服务器进行纪录。当然，这里扯远了，还是回到胶水纪录。一般来说，域名注册商的网站都可以添加胶水纪录，而有的注册商则是需要付费才能添加，这取决于你的服务提供商。同时，有的注册商并没有使用 「胶水纪录」这个词，而是使用 「注册 DNS 服务器」或者 「DNS Host」，例如我使用的[腾讯云](https://cloud.tencent.com/document/product/242/54158)就是称作 「DNS Host」如下图：

<center>
    <img src="https://32cf906.webp.li/2024/09/dns-dnspod.png" width="70%" alt="DNS 胶水纪录">
</center>

在完成以后，我们还需要将 `exmaple.dns` 的 NS 服务器改为 `ns1.example.dns` 和 `ns2.example.dns`[^3]。

#### 安装 PowerDNS 和 MariaDB 与 PowerDNS 初始配置

我们需要在两台服务器上都安装 PowerDNS 和 MariaDB，这里，我让 NS1 作为主要节点而 NS2 作为备份节点 (两台服务器均使用 Debian 12)：

```shell
sudo su
apt-get update && apt-get upgrade -y 

# 导入 PowerDNS 和 MariaDB 官方源和签名 并 安装
curl -sSL https://repo.powerdns.com/FD380FBB-pub.asc | gpg --dearmor > /usr/share/keyrings/powerdns.gpg
cat > /etc/apt/sources.list.d/pdns.list << EOF
deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/powerdns.gpg] http://repo.powerdns.com/debian $(lsb_release -sc)-auth-49 main
deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/powerdns.gpg] http://repo.powerdns.com/debian $(lsb_release -sc)-rec-50 main
deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/powerdns.gpg] http://repo.powerdns.com/debian $(lsb_release -sc)-dnsdist-19 main
EOF

## 优先使用 PowerDNS 官方源进行安装
cat >> /etc/apt/preferences.d/pdns << EOF
Package: pdns-*
Pin: origin repo.powerdns.com
Pin-Priority: 600
EOF

curl -sSL https://mariadb.org/mariadb_release_signing_key.asc | gpg --dearmor > /usr/share/keyrings/mariadb.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/mariadb.gpg] https://mirror-cdn.xtom.com/mariadb/repo/11.4/debian $(lsb_release -sc) main" > /etc/apt/sources.list.d/mariadb.list

## 需要安装 geoip 插件，为后续配置 geodns 做准备
apt-get update && apt-get install pdns-server pdns-backend-mysql pdns-backend-geoip mariadb-server 

## 配置数据库同步

### 在 NS1 里执行如下命令：
mkdir /var/lib/mysql-bin
chown mysql:mysql /var/lib/mysql-bin

cat > /etc/mysql/mariadb.conf.d/61-master.cnf <<EOF
[mysqld]
skip-host-cache
skip-name-resolve
bind-address = 0.0.0.0 # 也可以修改为其他 NS2 可以访问到的 NS1 的 IP 

server-id = $SRANDOM
log-bin = /var/lib/mysql-bin/binlog
expire_logs_days = 7
EOF

#### 通过 iptables 限制 3306 的访问
iptables -I INPUT -p tcp --dport 3306 -j DROP
iptables -I INPUT -s 127.0.0.1 -p tcp --dport 3306 -j ACCEPT 
iptables -I INPUT -s <NS2 的 IP 或者其他指定 IP 段> -p tcp --dport 3306 -j ACCEPT  

#### 新建一个 backup 用户，使得 NS2 可以访问 NS1 所有数据库
mariadb -e "GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* to 'backup'@'%' identified by 'backup_pass';"

#### 重启 MariaDB 并查看运行情况
systemctl restart mariadb
systemctl status mariadb

### 在 NS2 里执行如下命令：
mkdir /var/lib/mysql-bin
chown mysql:mysql /var/lib/mysql-bin

cat > /etc/mysql/mariadb.conf.d/61-slave.cnf <<EOF
[mysqld]
skip-host-cache
skip-name-resolve

server-id = $SRANDOM
relay-log = /var/lib/mysql-bin/relaylog
expire_logs_days = 7
EOF

sed -i 's/expire_logs_days/#expire_logs_days/g' /etc/mysql/mariadb.conf.d/50-server.cnf

#### 仅允许本机访问 3306
iptables -I INPUT -p tcp --dport 3306 -j DROP
iptables -I INPUT -s 127.0.0.1 -p tcp --dport 3306 -j ACCEPT

#### 重启 MariaDB 并查看运行情况
systemctl restart mariadb
systemctl status mariadb

### 检查 NS1 和 NS2 两台服务器的数据库
#### 在 NS1 中运行
mariadb -e "show binary logs;\G" # 如出现 binlog.000001 和 file size 为 325 则正常（新安装的情况下）
#### 在 NS2 中运行
mariadb -e "CHANGE MASTER TO MASTER_HOST='<NS1-IP ADDR>', MASTER_USER='backup', MASTER_PASSWORD='backup_pass', MASTER_PORT=3306, MASTER_LOG_FILE='binlog.000001', MASTER_LOG_POS=325; START SLAVE; SHOW SLAVE STATUS\G"


### 导入 PowerDNS 数据库
#### 在 NS1 中运行
mariadb -u root
CREATE DATABASE pdns_database DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; 
GRANT ALL ON pdns_database.* TO 'pdns_user'@'%' IDENTIFIED BY 'pdns_password'; # pdns_user 和 pdns_password 是 PowerDNS 数据库的用户名和密码
FLUSH PRIVILEGES; 
EXIT;

cd /usr/share/pdns-backend-mysql/schema
mariadb -u pdns_user --default-character-set=utf8mb4 -p pdns_database < schema.mysql.sql
mariadb -u pdns_user --default-character-set=utf8mb4 -p pdns_database < enable-foreign-keys.mysql.sql

#### 在 NS2 中运行
mariadb -e "show databases;\G"  # 如已经同步 pdns_database 则为正常
```

在完成数据库设置后，我们就可以开始对 PowerDNS 进行初始化配置，首先删除默认安装的 `/etc/powerdns/pdns.d/bind.conf`, 然后添加一个 `/etc/powerdns/pdns.d/dns.conf` 并输入：

```shell
cat >> /etc/powerdns/pdns.d/dns.conf << EOF
launch=gmysql
gmysql-host=localhost
gmysql-user=pdns_user # 数据库用户名
gmysql-dbname=pdns_database # 数据库名
gmysql-password=pdns_password # 数据库密码
gmysql-dnssec=yes
default-soa-content=ns1.example.dns hostmaster.example.dns 0 3600 14400 604800 3600
api=yes
api-key=random_api_key # api key 可以随意更换，比如使用 openssl 生成：openssl rand -base64 16
local-address=0.0.0.0 ::
local-port=53
webserver-address=0.0.0.0
webserver-allow-from=127.0.0.1, ::1, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16
webserver-port=8081
EOF
```

在完成配置后，需要重启 PowerDNS：`systemctl restart pdns`，但是在重启之前，我们可以注意到 PowerDNS 占用得是 `53` 端口，但是默认情况下，Debian/Ubuntu 都会被系统的 `systemd-resolved` 占用, 所以，我们需要关闭它：

```shell
# 仅针对 Debian 11/12，其他系统请参考对应系统的教程
sudo su 
systemctl stop systemd-resolved && systemctl disable systemd-resolved
cp /etc/resolv.conf /etc/resolv.conf.bak && rm -rf /etc/resolv.conf
cat >> /etc/resolv.conf << EOF
nameserver  1.1.1.1
nameserver  8.8.8.8
EOF

systemctl restart networking
```

#### PowerDNS-Admin 安装

[PowerDNS Admin](https://github.com/PowerDNS-Admin/PowerDNS-Admin) 是一个基于 Django 的 PowerDNS 管理软件，一般来说，我们会单独部署而不是部署在 NS1 或者 NS2 上。GitHub 上有对应的 Docker 和本地安装教程，这里，我已 K3s/K8s 为例：

首先创建 namespace：
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: powerdns
```

然后创建 PV 和 PVC，这是为了持久化存储数据库上的数据，我这里使用的是 `local-host` 的存储方式，也可以使用其他的存储后端，比如 NFS 或者 Ceph：
```yaml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pdns-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /data/pdns
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - base-server

---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pdns-mysql-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /data/pdns
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - base-server

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pdns-pvc
  namespace: powerdns
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  storageClassName: local-storage
  volumeName: pdns-pv

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pdns-mysql-pvc
  namespace: powerdns
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  storageClassName: local-storage
  volumeName: pdns-mysql-pv
```

随后创建 `Deployment`, `Serivce` 和 `Ingress`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: powerdns
  namespace: powerdns
spec:
  selector:
    matchLabels:
      app: powerdns
  template:
    metadata:
      labels:
        app: powerdns
    spec:
      nodeName: base-server
      containers:
      - name: powerdns
        image: powerdnsadmin/pda-legacy:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
        env:
        - name: SECRET_KEY
          value: "<random-secret-key>"
        - name: SQLALCHEMY_DATABASE_URI
          value: "mysql://powerdns-admin-user:powerdns-admin-password@127.0.0.1/powerdns-admin-database"
        - name: GUNICORN_TIMEOUT
          value: "60"
        - name: GUNICORN_WORKERS
          value: "4"
        - name: GUNICORN_LOGLEVEL
          value: "DEBUG"
        - name: OFFLINE_MODE
          value: "False"
        volumeMounts:
        - name: pdns-pvc
          mountPath: /data
      - name: powerdns-admin-mariadb
        image: mariadb:11.4
        ports:
        - containerPort: 3306
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "mysql_root_password"
        - name: MYSQL_DATABASE
          value: "powerdns-admin-database"
        - name: MYSQL_USER
          value: "powerdns-admin-user"
        - name: MYSQL_PASSWORD
          value: "powerdns-admin-password"
        volumeMounts:
        - name: pdns-mysql-pvc
          mountPath: /var/lib/mysql
      volumes:
      - name: pdns-pvc
        persistentVolumeClaim:
          claimName: pdns-pvc
      - name: pdns-mysql-pvc
        persistentVolumeClaim:
          claimName: pdns-mysql-pvc

---
apiVersion: v1
kind: Service
metadata:
  name: powerdns
  namespace: powerdns
spec:
  selector:
    app: powerdns
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: ClusterIP

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-pdns
  namespace: powerdns
spec:
  rules:
  - host: pdns.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: powerdns
            port:
              number: 80
```

注册的第一个账号就是 Admin 账号，如果没有多人使用的需求即可在 `Settings - Authentication` 里关闭 `Allow users to sign up`。在 Server 填入 NS1 或者 NS2 的信息即可。 而后，就可以开始配置 GeoDNS 了。

#### GeoDNS 配置

由于 Maxmind GeoIP 开始要求 GeoLite 的用户注册账号并使用密钥才能下载数据库，所以第一步，我们需要去 [GeoLite2](https://dev.maxmind.com/geoip/geolite2-free-geolocation-data) 注册账号并创建 License Key。在得到 Key 以后，我们就需要在 NS1 和 NS2 种安装 `sudo apt-get install geoipupdate`，并将 `AccountID` 和 `License Key` 存入服务器中:

```shell
sudo su 
cat > /etc/GeoIP.conf << EOF
AccountID XXXXXX
LicenseKey XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
EditionIDs GeoLite2-Country GeoLite2-City GeoLite2-ASN
EOF

sudo geoipupdate -v 
```

如果一切顺利，所有的 `.mmdb` 都会存放到 `/usr/share/GeoIP` 这个路径下面。回到 NS1 和 NS2 的 `/etc/powerdns/pdns.d/dns.conf` 里，添加如下内容并重新启动 PowerDNS 即可：

```shell
enable-lua-records=yes # 启动 lua script 
launch+=geoip # 启动 geoip 插件
geoip-database-files=/usr/share/GeoIP/GeoLite2-City.mmdb /usr/share/GeoIP/GeoLite2-Country.mmdb /usr/share/GeoIP/GeoLite2-ASN.mmdb
log-dns-queries=yes 
```
回到 PowerDNS-Admin 里，我们还需要在 `Settings - Zone Records` 里打开 LUA 才能在解析纪录里使用 lua script。Lua 纪录有很多用法， 详细可以参考[官网](https://doc.powerdns.com/authoritative/lua-records/), 这里，我只介绍 GeoDNS 需要怎么设置：

我们可以首先设置一条 Lua 纪录给 `www.example.com`：`A    "pickclosest({'249.209.110.226','160.38.17.187','66.167.146.39'})"` 然后使用 [Ping Test](https://tools.keycdn.com/ping) 进行测试：

<center>
    <img src="https://32cf906.webp.li/2024/09/www-example-com-dns.png" width="70%" alt="GeoDNS 测试">
</center>

我们可以看到，不同的地方已经可以解析到不同的 IP 了，这里 Loss 100% 是因为测试 IP 都是随机生成的，理论上应该也是 ping 不通才合理，我们这里换成真实的 IP 试试：

1. LAX: `67.198.150.72`
2. AMS: `78.142.195.195`
3. SIN: `89.28.239.46`

<center>
    <img src="https://32cf906.webp.li/2024/09/www-example-com-geodns-2.png" width="70%" alt="GeoDNS 测试">
</center>

我们可以看到，不同地区已经解析到不同地区的 IP 了，全球 Ping 的延迟也都降到了 100ms 以下(除了印度以外)。

## 从接入点到集群

上一篇文章里也提及了通过 `IPTABLES` 从接入点到集群的 External IP 的端口转发，但是经过测试发现，`IPTABLES` 无法利用一些 TCP 拥塞控制算法以提高网络吞吐和延迟，经过激情网络冲浪，发现了如下的一些工具：

1. [realm: A simple, high performance relay server written in rust](https://github.com/zhboner/realm)
2. [gost: GO Simple Tunnel](https://github.com/go-gost/gost)
3. [Nginx - Stream Module](https://nginx.org/en/docs/stream/ngx_stream_core_module.html)
4. [Haproxy](https://www.haproxy.org/)

大概不止这几种工具，只是随手举出了这四个。这些对比 `IPTABLES` 的好处是可以利用 BBR 等算法进一步提高 TCP 的传输。在对比了一番以后，我最终选择了 Nginx。

### 安装 Nginx

与平时安装 Nginx 略微不同，我们直接通过 `apt` 安装的 Nginx 不带 `stream` 模块，我们可以通过 `nginx -V | grep steram` 进行查看。这里我选择直接去下载源码编译安装：

```shell
sudo apt -y install gcc make libssl-dev zlib1g-dev libgd-dev libgeoip-dev libpcre2-dev libpcre3-dev
wget -O nginx.tar.gz https://nginx.org/download/nginx-1.23.1.tar.gz
tar -xvf nginx.tar.gz && cd ./nginx-1.23.1/
sudo mkdir /usr/lib/nginx && sudo mkdir /var/log/nginx && sudo mkdir /etc/nginx && sudo mkdir /var/cache/nginx

./configure \
--prefix=/etc/nginx \
--user=root \
--group=root \
--sbin-path=/usr/sbin/nginx \
--modules-path=/usr/lib/nginx/modules \
--conf-path=/etc/nginx/nginx.conf \
--error-log-path=/var/log/nginx/error.log \
--http-log-path=/var/log/nginx/access.log \
--pid-path=/var/run/nginx.pid \
--lock-path=/var/run/nginx.lock \
--http-client-body-temp-path=/var/cache/nginx/client_temp \
--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
--with-file-aio \
--with-threads \
--with-http_addition_module \
--with-http_auth_request_module \
--with-http_dav_module \
--with-http_flv_module \
--with-http_gunzip_module \
--with-http_gzip_static_module \
--with-http_mp4_module \
--with-http_random_index_module \
--with-http_realip_module \
--with-http_secure_link_module \
--with-http_slice_module \
--with-http_ssl_module \
--with-http_stub_status_module \
--with-http_sub_module \
--with-http_v2_module \
--with-mail \
--with-mail_ssl_module \
--with-stream \
--with-stream_realip_module \
--with-stream_ssl_module \
--with-stream_ssl_preread_module

sudo make && sudo make install && sudo mkdir /etc/nginx/sites-available && sudo sudo mkdir /etc/nginx/sites-enabled
```

在完成安装后，我们还需要在 `systemd` 中加入配置文件对 service 进行控制：

```shell
sudo su 
cat > /etc/systemd/system/nginx.service << EOF
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t -c /etc/nginx/nginx.conf
ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx.conf
ExecReload=/usr/sbin/nginx -s reload -c /etc/nginx/nginx.conf
ExecStop=/bin/kill -s QUIT
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now nginx
```

这时，我们在看 `nginx -V | grep stream` 就能发现模块已经正常安装了。

通过 stream 模块，我们就可以通过 nginx 对 TCP/UDP 流量进行转发，同时，还可以通过 SNI proxy 来转发 HTTPS 流量到源站，这里我给出一个样例：

```shell
stream {
    upstream cluster {
        server 192.168.101.151:443;
        server 192.168.101.152:443;
    }

    map $ssl_preread_server_name $upstream_server {
        default cluster;
    }

    server {
        listen 443;
        proxy_pass $upstream_server;
        ssl_preread on;  # Enable SNI reading

    }
}
```

至此，我们已经完成了从 client 到 entrance 再到 source 的两步走流程。当然，选择 nginx 的原因不仅仅是 TCP 加速，更是因为可以根据域名进行不同后端的分流，这些应该是 IPTABLES/REALM 这些工具无法达到的。而至于为什么不用 HAProxy 则是因为本人不善于使用它，是我的错。


[^1]: 其实也是因为没有 AS 号在手，不然就是「我选择自建 Anycast DNS 服务器」了 ：）
[^2]: 本文中所提及的所有 IP 地址（包括 IPV4 和 IPV6）均是通过 [IPVOID](https://www.ipvoid.com/) 随机生成
[^3]: 由此可以看出，如果域名本身不需要作为自身的 NS 服务器，则无需设置胶水纪录，即，可以省略这一步