#!/bin/sh
# This script will be executed in late_start service mode
MODPATH=${0%/*}

# log
exec 2> $MODPATH/logs/service.log
set -x

. $MODPATH/utils.sh || exit $?

wait_for_boot

# Load config
load_config() {
    # Check for config first
    local internal_config="/sdcard/.fakehttp.conf"
    local module_config="$MODPATH/conf/fakehttp.conf"
    if [ -f "$internal_config" ]; then
        source "$internal_config"
        return 0
    elif [ -f "$module_config" ] && [ ! -f "$internal_config" ]; then
        cp "$module_config" "$internal_config" && source "$internal_config"
        return 0
    else
        interface="wlan0"
        hostname="www.speedtest.cn"
        logfile="/sdcard/.fakehttp.log"
        silent="1"
        return 0
    fi
}

load_config

set -- -d -z

# ----------------- 多值参数解析 -------------------

# 解析 interface (支持 all 或 逗号分隔的多个网卡)
if [ -n "${interface+x}" ]; then
    if [ "$interface" == "all" ]; then
        set -- "$@" "-a"
    else
        OLD_IFS="$IFS"; IFS=","
        for item in $interface; do
            set -- "$@" "-i" "$item"
        done
        IFS="$OLD_IFS"
    fi
fi

# 解析 hostname (支持逗号分隔，同时添加 -h 和 -e)
if [ -n "${hostname+x}" ]; then
    OLD_IFS="$IFS"; IFS=","
    for item in $hostname; do
        set -- "$@" "-h" "$item" "-e" "$item"
    done
    IFS="$OLD_IFS"
fi

# 解析 payload (支持逗号分隔)
if [ -n "${payload+x}" ]; then
    OLD_IFS="$IFS"; IFS=","
    for item in $payload; do
        set -- "$@" "-b" "$item"
    done
    IFS="$OLD_IFS"
fi

# ----------------- 单值参数解析 -----------------
[ -n "${mark+x}" ] && set -- "$@" "-m" "$mark"
[ -n "${mask+x}" ] && set -- "$@" "-x" "$mask"
[ -n "${number+x}" ] && set -- "$@" "-n" "$number"
[ -n "${repeat+x}" ] && set -- "$@" "-r" "$repeat"
[ -n "${logfile+x}" ] && set -- "$@" "-w" "$logfile"
[ -n "${silent+x}" ] && [ "$silent" -eq 1 ] && set -- "$@" "-s"
[ -n "${ttl+x}" ] && set -- "$@" "-t" "$ttl"
[ -n "${pct+x}" ] && set -- "$@" "-y" "$pct"

$MODPATH/bin/fakehttp "$@"

check_fakehttp_is_up

#EOF
