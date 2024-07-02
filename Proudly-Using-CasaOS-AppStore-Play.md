# 自豪地使用 CasaOS-AppStore-Play

> This article is written in Simplified Chinese, which the author is familiar with, and users of other languages are advised to use their own translation tools to read it.

在创建本商店之前，我在本地保存 docker-compose.yml 文件作为 Docker 应用的备份方案。在 CasaOS 支持第三方商店后，我想仓库既可以当做备份，又能作为应用商店把 Docker 应用分享给大家，这不是两全其美吗？

鲁迅说得好，自己动手，丰衣足食。所以你可以感受到这个商店的特点：

- **极具个人偏好的**
- **具有本地特色的**
- **尽善尽美的**

在维护过程中，我逐步完善了商店的功能，并积累了不少技术细节，我觉得有必要将它们记录下来。

## 自动打包发布

**问题：** 在三方商店推行之初，官方示例是下载整个仓库 zip 文件的。但是它包含了应用图标、预览图等图片文件，导致**体积过大，网络不顺畅时下载需要等待很久**。而且 CasaOS AppStore 的机制并不使用本地图片资源。

**解决：** 使用 GitHub Actions 将仓库打包成 Releases 并进行过滤，只包含 json 和 yml 文件作为商店源文件（以下简称源文件），将源文件精简到几百 KB。

## 分架构打包

**问题：**  由于 [LinuxServer 放弃支持 armv7 镜像](https://www.linuxserver.io/blog/a-farewell-to-arm-hf)，而国内有众多玩客云用户，为了满足这部分用户的需求，May@IceWhale 找到我，希望借社区的力量做一个**支持 armv7 的商店**。我考虑到必然会有部分应用重叠，而且需要重复维护，因此我并没有立即响应。半天后，我想到一个比较优雅的方案：在一个仓库内，根据架构分别打包，这样就可以减少重复维护的工作量。

**解决：**

1. 以 Apps 目录为基础，打包 armv7 架构时，将 Apps_arm 目录下的 .yml 文件复制并覆盖 Apps 目录下的同名文件。
2. 在压缩成 zip 文件时，通过识别 `x-casaos: architectures: - arm`  字段来过滤，实现只打包支持 armv7 的 .yml 文件的目的。
3. 将三种架构 (amd64, arm64, arm) 分别打包，提供专属架构源。

添加专属架构源有两个好处：一是可以某些应用可以提供专属架构的镜像支持；二是添加后商店中只出现本架构支持的应用，这是目前最佳的解决方案。

## 源文件同步上传到 OSS

**问题：** 为了避免我个人使用的域名被公开传播，商店源一直使用的是 eu.org 免费域名。然而，在国内部分地区部分运营商的网络环境下，**eu.org 域名会受到 DNS 污染**，根据部分用户反馈，添加源时会出现“假成功”的提示，实际无法加载源的内容。

**解决：** 将 zip 文件同步上传到阿里云 OSS，为这部分用户提供有限的服务。

## 发布时统计应用数

**问题：** 原本发布 Releases 时只显示最后一条 commit message，**期间更新了什么不够清晰**。

**解决：** 在 GitHub Actions 中增加 `Get Commit Messages` 步骤，方便用户查看，输出更详细的发布内容，并根据 yml 文件统计相应架构的应用数量。

## 使用 CDN 加速

**问题：** 源文件原本是使用 Cloudflare Worker 从 GitHub 拉取源文件做转发，但是随着用户数增多（根据 CF 的数据统计，24小时内独立访问者13.41k，请求 1.65M(million百万)，提供数据31GB），**远远超出了免费计划的请求限制**。

**解决：** 将源文件转移到阿里云 OSS，并为了缓解 OSS 的流量压力，叠加了 Cloudflare 免费的 CDN 加速。实测只有在每次更新源文件后会有短暂的流出流量，其余时候都由 Cloudflare 提供流量。 并且在 GitHub Actions 中增加了每次更新源文件后调用 Cloudflare API 清除 CDN 缓存的步骤，让 CDN 及时从 OSS 获取最新的源文件。

## 只在必要时重新发布

**问题：** 原本是 GitHub Actions 设置提交就自动发布，有时可能只更改了 README.md 或图片，**zip 的内容并没有改变，也重新发布，同时下游又重新拉取，造成资源浪费**。

**解决：** 将 Actions 的触发条件改为 `push: paths:` ，当 `*.yml` 文件有提交时才会重新发布。

## 最后

截至目前商店 90+ 应用，基本都是我亲自安装体验过。

以上，记录下来供后人借鉴，不仅是一个应用商店的建设历程，还是我对社区贡献的一份心力，永远保持对最优解的思考。

希望通过 CasaOS-AppStore-Play ，能让更多人感受到便捷部署应用的乐趣，并参与到 Docker 生态的共建中。 💕
