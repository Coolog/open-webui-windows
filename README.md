# Open WebUI Windows 一键安装包

[![Build Windows Installer](https://github.com/Coolog/open-webui-windows/actions/workflows/build-installer.yml/badge.svg)](https://github.com/Coolog/open-webui-windows/actions/workflows/build-installer.yml)

本安装包将在 Windows 系统上一键部署 Open WebUI + Ollama + Embedding 代理服务。

## ✨ 特点

- **零依赖安装** - 内置 Python 3.11，无需预装任何软件
- **一键安装** - 双击 exe 即可完成全部配置
- **自动下载模型** - 自动安装 Ollama 并下载所需模型
- **完全离线运行** - 安装完成后无需联网即可使用

## 📥 下载安装

从 [Releases](https://github.com/Coolog/open-webui-windows/releases) 页面下载最新版本的 `OpenWebUI-Setup-x.x.x.exe`

## 📦 包含内容

- **Python 3.11** (嵌入式版本，内置)
- **Open WebUI** - 现代化的 AI 对话界面
- **Ollama** - 本地大模型运行时
- **Embedding 代理** - RAG 功能的 embedding 服务
- **预装模型**:
  - `qwen2.5:7b` - 推理模型
  - `qwen3-embedding:latest` - Embedding 模型

## 💻 系统要求

- **操作系统**: Windows 10/11 (64位)
- **内存**: 建议 16GB 以上（运行 7B 模型）
- **磁盘**: 至少 20GB 可用空间
- **网络**: 首次安装需要联网下载模型（约 10GB）

> ⚠️ **无需预装 Python！** 安装包已内置 Python 3.11

## 🚀 安装步骤

1. 双击运行 `OpenWebUI-Setup-x.x.x.exe`
2. 选择安装目录（可自定义）
3. 等待安装完成（首次需下载约 10GB 模型文件）
4. 安装完成后可选择立即启动

## 📖 使用方法

### 启动服务

```
双击运行 start.bat 或桌面快捷方式
```

### 访问界面

启动后在浏览器中访问: **http://localhost:8080**

首次访问需要注册管理员账号。

### 停止服务

```
双击运行 stop.bat 或直接关闭启动窗口
```

## 📁 目录结构

```
安装目录/
├── python/                 # 内置 Python 3.11
├── app/                    # 程序文件
│   ├── logs/              # 运行日志
│   ├── embed_proxy.py     # Embedding 代理
│   └── requirements.txt   # Python 依赖
├── data/                   # 用户数据
│   ├── cache/             # 缓存文件
│   ├── uploads/           # 上传的文档
│   ├── vector_db/         # 向量数据库
│   └── webui.db           # 主数据库
├── start.bat              # 启动脚本
├── stop.bat               # 停止脚本
└── install.bat            # 安装脚本
```

## ⚙️ 端口说明

| 服务 | 端口 | 说明 |
|------|------|------|
| Open WebUI | 8080 | Web 界面 |
| Embedding Proxy | 8001 | Embedding 服务 |
| Ollama | 11434 | 模型服务 |

## 🔧 常见问题

### Q: 模型下载失败？

可以手动下载模型：
```cmd
ollama pull qwen2.5:7b
ollama pull qwen3-embedding:latest
```

### Q: 端口被占用？

先运行 `stop.bat` 停止所有服务，或手动结束占用端口的进程。

### Q: 如何备份数据？

复制 `data` 目录即可备份所有用户数据。

## 🗑️ 卸载

1. 从控制面板或设置中卸载 "Open WebUI"
2. 卸载时可选择是否保留用户数据

## 📝 更新日志

### v1.0.0
- 初始版本
- 内置 Python 3.11，无需预装
- 支持 Open WebUI + Ollama + Embedding 代理
- 预装 qwen2.5:7b 和 qwen3-embedding:latest 模型

## 📄 许可证

MIT License
