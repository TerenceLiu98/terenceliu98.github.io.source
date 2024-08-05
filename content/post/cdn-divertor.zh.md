---
title: "🛜 境内外 CDN 分流配置"
date: 2024-01-29T00:00:00+08:00
draft: false
tags: ['网络配置','博客']
comment: true
series: ["杂文"]
---

本文纯属个人记录，不保证是最优解决方案，仅供参考。 对于博客的境内外 CDN 分流有很多更加优雅的方式，而我选择了最蠢的「跳转」。

<!--more-->

## 前置条件

1. 我的静态博客是托管在 [GitHub Page](https://pages.github.com)，并且使用了 [Cloudflare](https://www.cloudflare.com) 的 CDN 服务。
2. 我拥有一台境内服务器，并且有一个已备案域名，可以满足国内 CDN 的要求。

## 境内外 CDN 分流

### 网站运行

我的网站部署流程是这样的：
1. 在本地编写博客内容，使用 [Hugo](https://gohugo.io) 生成静态网页进行内容渲染进行检查。
2. 将 source file 推动到 [TerenceLiu98.github.io.source](https://github.com/terenceliu98.github.io.source) 仓库，使用 GitHub Action 进行自动部署。
3. 在 GitHub Action 中，使用 Hugo 生成静态网页，并将生成的网页推送到 [TerenceLiu98.github.io](https://github.com/terenceliu98.github.io)
4. 在 Cloudflare 中，将 [TerenceLiu98.github.io](https://github.com/terenceliu98.github.io) 仓库的内容进行 CDN 加速。


### 具体配置

你需要在国内的服务器上搭建一个 HTTP 服务，用于分流境内的请求。这里我使用了 [Nginx](https://www.nginx.com) 作为 HTTP 服务，因为我从一开始就在使用 nginx 所以相对熟悉。不过你也可以使用其他 HTTP 服务，比如 [Caddy](https://caddyserver.com)，Caddy 有一个很好的特性，就是可以自动申请 HTTPS 证书，这样你就不需要自己去申请证书了。我这里使用 ACME 进行证书申请，所以就不再使用 Caddy 了。

```bash
server {
       	listen 80;
      	listen [::]:80;

      	server_name blog.rho.ac.cn;
	return 301 https://$host$request_uri;
}

server {
        listen 443 ssl;
        server_name blog.rho.ac.cn;
        ssl_certificate /home/ubuntu/acme-script/ssl/rho.ac.cn.pem;
        ssl_certificate_key /home/ubuntu/acme-script/ssl/rho.ac.cn.key;
	root /var/www/terenceliu98.github.io;
	index index.php index.html index.htm;

  location / {
  	try_files $uri $uri/ =404;
  }

}
```

其中，`server_name` 是准备的备案后域名，`root` 指向的是我存储博客内容的地方，`index` 指定了默认的首页。`ssl_certificate` 和 `ssl_certificate_key` 指定了 HTTPS 证书的位置。你也可以对 nginx 配置文件进行定制，这里不再赘述。在准备好这些以后，可以尝试运行网站，如果没有问题，那么就可以进行下一步了。

当然，这里应该会遇到一个域名错误的问题，因为在 Hugo 里我们配置了 CNAME，所以它在渲染的时候会将域名替换成 CNAME 中指定的域名，这样就会出现域名不匹配的问题。这里我使用了一个很蠢的方式解决，就是在 Hugo 渲染之后，进行域名替换。这里我使用了一个 Bash 脚本，将域名替换成了我准备的备案后域名。


```bash
git restore . && git pull

for file in $(find -iname '*.html'); do
	sed -i 's/blog.cklau.cc/blog.rho.ac.cn/g' $file
done
```

在网站可以正常运行后，我们仅需要在腾讯云的 CDN 控制台里添加自己的域名即可，将域名解析到提供的 CNAME，主源站指向自己国内的服务器 IP，配置好回源 Host 即可[^1]。其他平台也是一样的方法，这里不再赘述。

Cloudflare 的配置也十分简单，仅需要在 Rules 里添加一个规则，我这里选择的是根据国家进行分流，这样虽然是一刀切，但是确实保证了用户的使用体验（也是因为我买不起 GeoDNS）。

### 后续

因为腾讯云 CDN 的 HTTPS 需要自己提供证书（也需要付费），所以我将刚才申请到的 ACME 证书添加到了指定的地方，不知道是否有可以自动化的方法，不然就需要三个月更新一次证书了 🥹 。


[^1]: HOST 就填自己的域名即可，不需要填 IP，因为我们已经配置了 HTTP 服务，所以需要域名进行分流。