# 安装步骤

文件预置步骤比较复杂，不打算上架。

1. 修改app.conf中的site.url，将其修改为leanote使用的域名:端口，默认监听启动机器的9001端口，如需变更，则修改docker-compose.yaml中的services.leanote.ports中的9001

```bash
mkdir -p /DATA/AppData/leanote
cd /DATA/AppData/leanote
wget https://raw.githubusercontent.com/leanote/leanote-docker/master/leanote.js
wget https://raw.githubusercontent.com/leanote/leanote-docker/master/app.conf
wget https://raw.githubusercontent.com/leanote/leanote-docker/master/dbinit.sh
vim https://raw.githubusercontent.com/leanote/leanote-docker/master/app.conf
```

2. 将leanote仓库的mongodb_backup/leanote_install_data目录拷贝到当前目录

```bash
git clone https://github.com/leanote/leanote.git
mv ./leanote/mongodb_backup/leanote_install_data ./
rm -rf ./leanote
```

3. docker-compose up -d

