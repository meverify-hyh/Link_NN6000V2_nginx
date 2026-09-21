#!/usr/bin/env bash

GITHUB_BASE="https://github.com/"
OPENWRT_PACKAGES_DIR="$BUILD_DIR/feeds/openwrt_packages"
update_golang() {
    if [[ -d ./feeds/packages/lang/golang ]]; then
        \rm -rf ./feeds/packages/lang/golang
        if ! git clone --depth 1 -b $GOLANG_BRANCH $GOLANG_REPO ./feeds/packages/lang/golang; then
            echo "错误：克隆 golang 仓库 $GOLANG_REPO 失败" >&2
            exit 1
        fi
        echo "✓ golang 软件包更新完成"
    fi
}
clone_packages() {
    local name="$1"
    local repo_url="$2"
    local target_dir="$3"
    local sparse_pattern="${4:-}"
    local pre_cmd="${5:-}"
    local post_cmd="${6:-}"
    local move_from="${7:-}"
    local move_to="${8:-}"
    
    if [ -n "$pre_cmd" ]; then
        (cd "$BUILD_DIR" && eval "$pre_cmd") || return 1
    rm -rf "$target_dir" 2>/dev/null || true
    if [ -n "$sparse_pattern" ]; then
        if ! git clone --filter=blob:none --no-checkout "$repo_url" "$target_dir"; then
            echo "错误：从 $repo_url 克隆 $name 仓库失败" >&2
        
        pushd "$target_dir" >/dev/null
        git sparse-checkout init --cone
        if ! git sparse-checkout set $sparse_pattern; then
            echo "错误：稀疏检出 $sparse_pattern 失败" >&2
            popd >/dev/null

# ---- 配置 vlan100 DHCP ----
cat >> "$BUILD_DIR/files/etc/config/dhcp" << 'EOF'

config dhcp 'vlan100'
    option interface 'vlan100'
    option start '100'
    option limit '150'
    option leasetime '12h'
    option ra 'hybrid'
    option dhcpv4 'server'
    option force '1'
    list ra_flags 'none'
EOF
