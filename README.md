[中文](/README.md)

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="./media/3x-ui-dark.png">
    <img alt="3x-ui" src="./media/3x-ui-light.png">
  </picture>
</p>

[![](https://img.shields.io/github/v/release/mhsanaei/3x-ui.svg?style=for-the-badge)](https://github.com/MHSanaei/3x-ui/releases)
[![](https://img.shields.io/github/actions/workflow/status/mhsanaei/3x-ui/release.yml.svg?style=for-the-badge)](https://github.com/MHSanaei/3x-ui/actions)
[![GO Version](https://img.shields.io/github/go-mod/go-version/mhsanaei/3x-ui.svg?style=for-the-badge)](#)
[![Downloads](https://img.shields.io/github/downloads/mhsanaei/3x-ui/total.svg?style=for-the-badge)](https://github.com/MHSanaei/3x-ui/releases/latest)
[![License](https://img.shields.io/badge/license-GPL%20V3-blue.svg?longCache=true&style=for-the-badge)](https://www.gnu.org/licenses/gpl-3.0.en.html)

**3X-UI** — 一个基于网页的高级开源控制面板，专为管理 Xray-core 服务器而设计。它提供了用户友好的界面，用于配置和监控各种 VPN 和代理协议。

> [!IMPORTANT]
> 本项目仅用于个人使用和通信，请勿将其用于非法目的，请勿在生产环境中使用。

作为原始 X-UI 项目的增强版本，3X-UI 提供了更好的稳定性、更广泛的协议支持和额外的功能。


# ubuntu安装x-ui，创建节点，并优化网络

更新
```
sudo apt update
```    

安装防火墙放行端口
```
sudo apt update && sudo apt install -y ufw && sudo ufw enable && sudo ufw allow 22/tcp && sudo ufw allow 5000/tcp && sudo ufw allow 7000/tcp && sudo ufw status
```  

安装汉化3x-ui面板
```
bash <(curl -Ls https://raw.githubusercontent.com/Firefly-xui/3x-ui/master/install.sh)
```

3x-ui自签证书
```
bash <(curl -Ls https://raw.githubusercontent.com/cyb3rm4gus/3x-ui-auto_add_ssl/refs/heads/main/3x-ui-autossl.sh)
```  

修改根地址后登录x-ui
```
www.nvidia.com
```  

优化对列调度和启动bbr加速
```
echo -e "net.core.default_qdisc=fq\nnet.ipv4.tcp_congestion_control=bbr" | sudo tee /etc/sysctl.d/99-custom-network.conf && sudo sysctl --system
```  

查找路径为：/etc/sysctl.conf的配置文件
```
# 启用 BBR 拥塞控制（优化 TCP 传输）
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# TCP 窗口缓冲区优化
net.ipv4.tcp_rmem = 4096 87380 8388608
net.ipv4.tcp_wmem = 4096 87380 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.optmem_max = 65536
net.ipv4.tcp_mem = 8388608 8388608 8388608

# 启用 TCP 快速打开（减少握手延迟）
net.ipv4.tcp_fastopen = 3

# 启用低延迟模式
net.ipv4.tcp_low_latency = 1

# TIME_WAIT 连接优化，减少僵尸连接占用
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1   # 适用于非 NAT 服务器
net.ipv4.tcp_fin_timeout = 10  # 释放连接更快
net.ipv4.tcp_keepalive_time = 60
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl = 20

# SYN 处理优化（防止 SYN Flood）
net.ipv4.tcp_max_syn_backlog = 8192
net.core.netdev_max_backlog

```  


完整文档请参阅 [项目Wiki](https://github.com/MHSanaei/3x-ui/wiki)。

## 特别感谢

- [MHSanaei](https://github.com/MHSanaei/3x-ui)
- [alireza0](https://github.com/alireza0/)

## 致谢

- [Iran v2ray rules](https://github.com/chocolate4u/Iran-v2ray-rules) (许可证: **GPL-3.0**): _增强的 v2ray/xray 和 v2ray/xray-clients 路由规则，内置伊朗域名，专注于安全性和广告拦截。_
- [Russia v2ray rules](https://github.com/runetfreedom/russia-v2ray-rules-dat) (许可证: **GPL-3.0**): _此仓库包含基于俄罗斯被阻止域名和地址数据自动更新的 V2Ray 路由规则。_



