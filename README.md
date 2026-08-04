# codex-install

一键安装 **ChatGPT (Codex) 桌面版** + **VC++ 运行库**。

微软商店里名为 "ChatGPT" 的官方应用，其 PackageFamilyName 为 `OpenAI.Codex`（商店 ID `9PLM9XGG6VKS`），
本脚本通过 winget msstore 官方源始终安装商店最新版。

## 一键安装

在 PowerShell 中运行：

```powershell
irm https://cdn.jsdelivr.net/gh/xinCodes/codex-install@main/install.ps1 | iex
```

或（推荐，先下载审计再执行）：

```powershell
irm https://cdn.jsdelivr.net/gh/xinCodes/codex-install@main/install.ps1 -OutFile install.ps1
./install.ps1
```

## 流程

| 步骤 | 内容 |
|------|------|
| 1/3 | 检查 Visual C++ x64 运行库；未安装则从本仓库 Releases 下载 `VC_redist.x64.exe` 静默安装 |
| 2/3 | `winget install` 从微软商店 (msstore) 获取最新 ChatGPT 包并安装/升级 |
| 3/3 | 验证 `OpenAI.Codex` 是否安装成功 |

## 说明

- 重复运行会自动检测：VC++ 已装则跳过，ChatGPT 已是最新则跳过（winget 返回 `-1978335189` 视为成功）。
- 安装 VC++ 时可能弹出 UAC 授权窗口，请点"是"。
- 脚本来自本仓库，执行前可先下载查看内容。
- jsDelivr 对 `@main` 有数小时缓存，更新脚本后稍等片刻再拉取。

## 手动安装（备用）

```powershell
winget install --id 9PLM9XGG6VKS --source msstore --accept-package-agreements --accept-source-agreements
```
