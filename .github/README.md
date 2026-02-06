# Open WebUI Windows Installer

这个仓库包含 Open WebUI 的 Windows 一键安装包构建配置。

## 自动构建

推送代码到 `main` 或 `master` 分支会自动触发构建。

创建 `v*` 格式的 tag 会自动创建 Release。

## 手动触发构建

1. 进入 GitHub 仓库的 Actions 页面
2. 选择 "Build Windows Installer" workflow
3. 点击 "Run workflow"

## 下载安装包

- **开发版**: 在 Actions 页面的 Artifacts 中下载
- **正式版**: 在 Releases 页面下载
