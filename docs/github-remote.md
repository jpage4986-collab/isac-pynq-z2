# 创建GitHub远程仓库

本地仓库已经完成，远程仓库名称建议使用 `isac-pynq-z2`。

## 方式一：GitHub网页

在GitHub新建一个空的私有仓库，名称填 `isac-pynq-z2`，不要自动创建README、.gitignore或License。复制仓库HTTPS地址后，在项目目录执行：

```powershell
cd D:\pynqz2\isac-pynq-z2
git remote add origin https://github.com/你的用户名/isac-pynq-z2.git
git push -u origin main --tags
```

## 方式二：GitHub CLI

安装并登录 `gh` 后执行：

```powershell
cd D:\pynqz2\isac-pynq-z2
gh auth login
gh repo create isac-pynq-z2 --private --source=. --remote=origin --push
git push origin --tags
```

远程建好后，把两名队友添加为仓库协作者。队友第一次接力：

```powershell
git clone https://github.com/你的用户名/isac-pynq-z2.git D:\pynqz2\isac-pynq-z2
cd D:\pynqz2\isac-pynq-z2
py -3.12 -m venv .venv
.\.venv\Scripts\pip.exe install -r requirements.txt
```
