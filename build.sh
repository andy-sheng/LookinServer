#!/bin/bash

# LookinServer 动态库打包脚本
# 支持多架构和 Debug/Release 构建配置

set -e

# 默认值
CONFIGURATION="Release"
ARCHITECTURES="arm64 x86_64"
PROJECT_NAME="LookinServer"
SCHEME="LookinServer"
OUTPUT_DIR="build"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -a, --arch ARCH        指定架构 (arm64, x86_64, 或 'arm64 x86_64' 用于通用库)"
    echo "  -c, --config CONFIG    构建配置 (Debug 或 Release, 默认: Release)"
    echo "  -o, --output DIR       输出目录 (默认: build)"
    echo "  -h, --help            显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0                           # 构建 Release 版本的通用库 (arm64 + x86_64)"
    echo "  $0 -c Debug                  # 构建 Debug 版本的通用库"
    echo "  $0 -a arm64 -c Release       # 构建 Release 版本的 arm64 架构"
    echo "  $0 -a x86_64 -c Debug        # 构建 Debug 版本的 x86_64 架构"
    echo ""
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--arch)
            ARCHITECTURES="$2"
            shift 2
            ;;
        -c|--config)
            CONFIGURATION="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}错误: 未知参数 '$1'${NC}"
            show_help
            exit 1
            ;;
    esac
done

# 验证配置
if [[ "$CONFIGURATION" != "Debug" && "$CONFIGURATION" != "Release" ]]; then
    echo -e "${RED}错误: 配置必须是 Debug 或 Release${NC}"
    exit 1
fi

# 打印构建信息
echo -e "${BLUE}=== LookinServer 动态库构建 ===${NC}"
echo -e "${YELLOW}项目名称:${NC} $PROJECT_NAME"
echo -e "${YELLOW}构建配置:${NC} $CONFIGURATION"
echo -e "${YELLOW}目标架构:${NC} $ARCHITECTURES"
echo -e "${YELLOW}输出目录:${NC} $OUTPUT_DIR"
echo ""

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 清理之前的构建
echo -e "${BLUE}清理之前的构建...${NC}"
xcodebuild clean -project ${PROJECT_NAME}.xcodeproj -scheme $SCHEME -configuration $CONFIGURATION

# 构建每个架构
BUILT_FRAMEWORKS=()
for ARCH in $ARCHITECTURES; do
    echo -e "${BLUE}正在构建 $ARCH 架构...${NC}"
    
    # iOS 设备构建
    if [[ "$ARCH" == "arm64" ]]; then
        DESTINATION="generic/platform=iOS"
        SDK="iphoneos"
    else
        DESTINATION="generic/platform=iOS Simulator"
        SDK="iphonesimulator"
    fi
    
    BUILD_DIR="$OUTPUT_DIR/build-$ARCH"
    
    xcodebuild build \
        -project ${PROJECT_NAME}.xcodeproj \
        -scheme $SCHEME \
        -configuration $CONFIGURATION \
        -destination "$DESTINATION" \
        -sdk $SDK \
        ARCHS="$ARCH" \
        VALID_ARCHS="$ARCH" \
        BUILD_DIR="$BUILD_DIR" \
        BUILD_ROOT="$BUILD_DIR" \
        ONLY_ACTIVE_ARCH=NO \
        SKIP_INSTALL=NO \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGN_IDENTITY="" \
        PROVISIONING_PROFILE=""
    
    # 查找构建产物
    FRAMEWORK_PATH=$(find "$BUILD_DIR" -name "${PROJECT_NAME}.framework" -type d | head -1)
    if [[ -n "$FRAMEWORK_PATH" ]]; then
        BUILT_FRAMEWORKS+=("$FRAMEWORK_PATH")
        echo -e "${GREEN}✅ $ARCH 架构构建完成: $FRAMEWORK_PATH${NC}"
    else
        echo -e "${RED}❌ $ARCH 架构构建失败${NC}"
        exit 1
    fi
done

# 如果只有一个架构，直接复制
if [[ ${#BUILT_FRAMEWORKS[@]} -eq 1 ]]; then
    FINAL_OUTPUT="$OUTPUT_DIR/${PROJECT_NAME}.framework"
    cp -R "${BUILT_FRAMEWORKS[0]}" "$FINAL_OUTPUT"
    echo -e "${GREEN}✅ 单架构框架已输出到: $FINAL_OUTPUT${NC}"
else
    # 合并多个架构为通用库
    echo -e "${BLUE}合并架构为通用库...${NC}"
    
    FINAL_OUTPUT="$OUTPUT_DIR/${PROJECT_NAME}.framework"
    
    # 复制第一个框架作为基础
    cp -R "${BUILT_FRAMEWORKS[0]}" "$FINAL_OUTPUT"
    
    # 使用 lipo 合并二进制文件
    BINARY_PATHS=()
    for FRAMEWORK in "${BUILT_FRAMEWORKS[@]}"; do
        BINARY_PATHS+=("$FRAMEWORK/${PROJECT_NAME}")
    done
    
    lipo -create "${BINARY_PATHS[@]}" -output "$FINAL_OUTPUT/${PROJECT_NAME}"
    
    echo -e "${GREEN}✅ 通用库已创建: $FINAL_OUTPUT${NC}"
fi

# 显示架构信息
echo -e "${BLUE}验证最终产物架构...${NC}"
lipo -info "$FINAL_OUTPUT/${PROJECT_NAME}"

# 清理临时文件
echo -e "${BLUE}清理临时文件...${NC}"
for ARCH in $ARCHITECTURES; do
    rm -rf "$OUTPUT_DIR/build-$ARCH"
done

# 显示最终结果
echo ""
echo -e "${GREEN}=== 构建完成 ===${NC}"
echo -e "${GREEN}框架位置: $FINAL_OUTPUT${NC}"
echo -e "${GREEN}配置: $CONFIGURATION${NC}"
echo -e "${GREEN}架构: $(lipo -info "$FINAL_OUTPUT/${PROJECT_NAME}" | cut -d: -f2 | xargs)${NC}"

# 显示框架信息
FRAMEWORK_SIZE=$(du -sh "$FINAL_OUTPUT" | cut -f1)
echo -e "${GREEN}框架大小: $FRAMEWORK_SIZE${NC}"

echo -e "${BLUE}构建脚本执行完成！${NC}"