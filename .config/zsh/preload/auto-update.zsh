#!/usr/bin/env zsh
return 0
#------------------------------------------------------------------#
# File:     auto-update-zsh.zsh                                    #
# Purpose:  检查并更新 dotfiles 配置                                #
# Author:   ashark                                                 #
#------------------------------------------------------------------#

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# config 别名
alias config_cmd='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查远程更新
check_updates() {
    
    # 获取远程更新
    if ! config_cmd fetch origin 2>&1; then
        return 0
    fi
    
    # 比较本地和远程
    local local_commit=$(config_cmd rev-parse HEAD)
    local remote_commit=$(config_cmd rev-parse origin/main 2>/dev/null || config_cmd rev-parse origin/master 2>/dev/null)
    
    if [[ "$local_commit" == "$remote_commit" ]]; then
        return 0
    fi
    
    # 显示更新信息
    print_info "发现远程更新："
    echo ""
    config_cmd log --oneline HEAD..origin/main 2>/dev/null || config_cmd log --oneline HEAD..origin/master 2>/dev/null
    echo ""
}

# 执行更新
do_update() {
    print_info "正在更新配置..."
    
    if config_cmd pull origin main 2>&1 || config_cmd pull origin master 2>&1; then
        echo ""
        print_success "✨ 配置更新成功！"
        echo ""
        print_info "更新内容："
        config_cmd log --oneline -5 --decorate --color=always
    else
        echo ""
        print_error "更新失败，请手动解决冲突"
        return 1
    fi
}

main() {
    check_updates
    
    echo -n "是否更新配置? [Y/n]: "
    read -r response
    
    if [[ "$response" =~ ^([nN][oO]|[nN])$ ]]; then
        print_info "取消更新"
        return 0
    fi
    
    do_update
}


main
