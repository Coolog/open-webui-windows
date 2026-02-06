# Open WebUI Windows 安装包 - 打包指南

## 准备工作

### 1. 安装 Inno Setup

下载并安装 Inno Setup 6.x：
https://jrsoftware.org/isdl.php

### 2. 准备图标文件

需要一个 `icon.ico` 文件作为程序图标。可以：
- 使用在线工具将 PNG 转换为 ICO
- 推荐网站: https://convertio.co/png-ico/

将 `icon.ico` 放到 `open-webui-windows` 目录下。

## 打包步骤

### 方法一：使用 Inno Setup GUI

1. 打开 Inno Setup Compiler
2. 点击 File → Open
3. 选择 `setup.iss` 文件
4. 点击 Build → Compile (或按 Ctrl+F9)
5. 等待编译完成
6. 安装包将生成在 `output` 目录下

### 方法二：使用命令行

```cmd
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" setup.iss
```

## 输出文件

编译成功后，将在 `output` 目录下生成：
- `OpenWebUI-Setup-1.0.0.exe` - 安装程序

## 文件清单

确保以下文件都在 `open-webui-windows` 目录下：

```
open-webui-windows/
├── embed_proxy.py      ✓ 必需
├── requirements.txt    ✓ 必需
├── install.bat         ✓ 必需
├── start.bat           ✓ 必需
├── stop.bat            ✓ 必需
├── setup.iss           ✓ 必需 (Inno Setup 配置)
├── README.md           ✓ 必需
├── icon.ico            ⚠ 需要添加
└── BUILD.md            📖 本文件
```

## 自定义配置

### 修改版本号

编辑 `setup.iss` 文件开头的定义：

```iss
#define MyAppVersion "1.0.0"
```

### 修改默认安装路径

编辑 `setup.iss` 中的 `DefaultDirName`：

```iss
DefaultDirName={autopf}\{#MyAppName}
```

### 修改预装模型

编辑 `install.bat` 中的模型下载部分：

```batch
ollama pull qwen3-embedding:latest
ollama pull qwen2.5:7b
```

## 测试建议

1. 在干净的 Windows 虚拟机中测试安装
2. 测试没有 Python 的情况
3. 测试没有 Ollama 的情况
4. 测试卸载是否干净

## 注意事项

- 首次安装需要下载约 5GB 的模型文件
- 安装过程需要管理员权限
- 建议在有稳定网络的环境下安装
