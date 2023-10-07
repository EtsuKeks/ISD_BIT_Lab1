#!/bin/bash

show_help()
{
    echo 'Usage: sudo karimullin_hw1 [OPTION]'
    echo
    echo 'OPTIONS:'
    echo 'START: Initialize a daemon for monitoring and show pid of daemon'
    echo 'STOP: Stop the daemon'
    echo 'STATUS: Show status of daemon and pid if currently running'
}

monitor_memory_usage()
{
    TOTAL_MEM=$(free -mt | grep "Mem:" | awk '{print $3}')
    MEM="$TOTAL_MEM Mb"

    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "$timestamp,$MEM" >> monitor_memory_usage.csv
}

su_required()
{
    user_id=`id -u`

    if [ "$user_id" != "0" ]; then
        echo "You need super user priviliges for this."
        exit
    fi
}

on_daemon_exit()
{
    if [ -e /var/run/karimullin_hw1.pid ]; then
        rm -f /var/run/karimullin_hw1.pid
    fi

    exit 0
}

daemon_pid()
{
    if [ -e /var/run/karimullin_hw1.pid ]; then
        echo $(cat /var/run/karimullin_hw1.pid)

        return
    fi

    echo "0"
}

daemon_running()
{
    if [ -e /var/run/karimullin_hw1.pid ]; then
        echo "1"
        return
    fi

    echo "0"
}

start_daemon()
{
    su_required

    if [ $(daemon_running) = "1" ]; then
        echo "daemon is already running..."
        exit 0
    fi

    rm monitor_memory_usage.csv
    touch monitor_memory_usage.csv

    var1="Timestamp"
    var2="Memory usage in Mb"
    echo "$var1, $var2" >> monitor_memory_usage.csv

    echo "starting daemon..."

    nohup bash $0 -l > /dev/null 2>&1 &

    daemon_pid=$!
    echo "Daemon process started with PID: $daemon_pid"
}

stop_daemon()
{
    su_required

    if [ $(daemon_running) = "0" ]; then
        echo "daemon is not running..."
        exit 0
    fi

    echo "stopping daemon..."

    kill $(daemon_pid)

    while [ -e /var/run/karimullin_hw1.pid ]; do
        continue
    done
}

daemon_loop()
{
    su_required

    if [ $(daemon_running) = "1" ]; then
        exit 0
    fi

    echo "$$" > /var/run/karimullin_hw1.pid

    trap 'on_daemon_exit' INT
    trap 'on_daemon_exit' QUIT
    trap 'on_daemon_exit' TERM
    trap 'on_daemon_exit' EXIT

    while true; do
        monitor_memory_usage

        # Run monitor every 5 seconds
        sleep 5
    done
}

daemon_status()
{
    current_pid=$(daemon_pid)

    if [ $(daemon_running) = "1" ]; then
        echo "karimullin_hw1 status: running with pid: $current_pid"
    else
        echo "karimullin_hw1 status: not running"
    fi
}

case $1 in
    'START')
        start_daemon
        exit
        ;;
    'STOP')
        stop_daemon
        exit
        ;;
    'STATUS')
        daemon_status
        exit
        ;;
    '-l' )
        # start daemon loop, used internally by START
        daemon_loop
        exit
        ;;
    '-h' | * )
        show_help
        exit
        ;;
esac