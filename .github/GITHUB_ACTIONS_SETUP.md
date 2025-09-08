# GitHub Actions 配置说明

## 概述

本项目配置了两个主要的 GitHub Actions 工作流：

1. **build-and-release.yml** - 自动构建和发布工作流
2. **quick-release.yml** - 手动快速发布工作流

## 工作流说明

### 1. 自动构建和发布 (build-and-release.yml)

**触发条件：**
- 推送到 `develop` 或 `main` 分支
- 创建标签 (以 `v` 开头)
- 对 `develop` 分支的 Pull Request

**功能：**
- 构建 Debug 和 Release 版本的框架
- 缓存构建产物以提高速度
- 上传构建产物为 Artifacts
- 自动创建 GitHub Release (仅当推送标签时)
- 生成校验和文件

### 2. 手动快速发布 (quick-release.yml)

**触发条件：**
- 手动触发 (在 GitHub Actions 页面)

**功能：**
- 验证版本号格式
- 检查标签是否已存在
- 构建 Release 版本
- 创建并推送标签
- 自动创建 GitHub Release

## 使用方法

### 自动发布 (推荐)

1. **开发分支发布：**
   ```bash
   git checkout develop
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **主分支发布：**
   ```bash
   git checkout main
   git tag v1.0.0
   git push origin v1.0.0
   ```

### 手动快速发布

1. 进入 GitHub 仓库的 Actions 页面
2. 选择 "Quick Release" 工作流
3. 点击 "Run workflow"
4. 输入版本号 (如 1.0.0)
5. 选择是否为预发布版本
6. 点击 "Run workflow" 执行

## 配置要求

### 必需权限
- `GITHUB_TOKEN` (自动提供) - 用于创建 Release 和推送标签

### 可选配置

#### 自定义 Xcode 版本
修改工作流中的 Xcode 版本选择：
```yaml
- name: Select Xcode version
  run: sudo xcode-select -s /Applications/Xcode_15.0.app/Contents/Developer
```

## 构建产物

每次成功构建后，将生成以下产物：

1. **GitHub Artifacts:**
   - `LookinServer-Debug-{commit-sha}`
   - `LookinServer-Release-{commit-sha}`

2. **GitHub Release (仅标签触发):**
   - `LookinServer-v{version}.zip` - 框架压缩包
   - `LookinServer-v{version}.zip.sha256` - 校验和文件

## 版本号规范

使用语义化版本控制 (Semantic Versioning)：
- 格式: `v{major}.{minor}.{patch}`
- 示例: `v1.0.0`, `v1.2.3`, `v2.0.0-beta.1`

## 故障排除

### 常见问题

1. **构建失败 - Xcode 版本不匹配**
   - 检查 runner 可用的 Xcode 版本
   - 更新工作流中的 Xcode 版本选择

2. **标签已存在错误**
   - 确保使用唯一的版本号
   - 删除冲突的本地/远程标签后重试

3. **权限不足错误**
   - 确保仓库启用了 Actions
   - 检查 GITHUB_TOKEN 权限设置

4. **构建脚本执行失败**
   - 确保 `build.sh` 有执行权限
   - 检查构建脚本兼容性

### 调试建议

1. 查看 Actions 运行日志
2. 检查构建产物和 Artifacts
3. 验证环境变量和 Secrets 配置
4. 本地测试构建脚本

## 下载和使用

用户可以通过以下方式下载和使用框架：

1. **从 GitHub Releases 下载：**
   - 访问仓库的 Releases 页面
   - 下载 `LookinServer-v{version}.zip`
   - 解压后将 `LookinServer.framework` 拖入 Xcode 项目

2. **使用校验和验证：**
   ```bash
   shasum -a 256 LookinServer-v1.0.0.zip
   cat LookinServer-v1.0.0.zip.sha256
   ```

## 进阶配置

### 添加通知
可以集成 Slack、Discord 等通知服务来接收构建状态。

### 多环境发布
可以扩展工作流支持不同的发布环境 (开发、测试、生产)。

### 自动化测试
在构建前添加单元测试和集成测试步骤。