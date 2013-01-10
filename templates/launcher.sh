#!/bin/sh

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
NAME=${opts:control-script}
BIN_PATH=${buildout:directory}/bin


startapp(){
    # Gunicorn
    $BIN_PATH/${django:control-script} run_gunicorn -D \
        -u ${opts:user} \
        -w ${opts:workers} \
        -p ${opts:pidfile} \
        -b unix:${opts:socketfile} \
        --log-file=${logs:instance_log}

    # FastCGI
    # $BIN_PATH/${django:control-script} runfcgi \
    #     maxchildren=1 \
    #     maxspare=1 \
    #     method=prefork \
    #     pidfile=${opts:pidfile} \
    #     socket=${opts:socketfile} \
    #     > /dev/null 2>&1 &
}

stopapp(){
    if [ -f ${opts:pidfile} ]; then
       kill `cat ${opts:pidfile}`
       rm -f -- ${opts:pidfile}
    fi
}

check_running(){
    # Check that the process is running. If not, restart
    if [ -f ${opts:pidfile} ]; then
        # We have a PIDFILE. Check if the process is running
        if [ `ps -u ${opts:user} | grep -i ${opts:control-script} | wc -l` -lt 1 ]; then
            startapp
        fi
    else
        startapp
    fi
}


case $1 in
    start)
        echo -n "Starting $NAME"
        startapp
        echo "."
        ;;
    stop)
        echo -n "Stopping $NAME"
        stopapp
        echo "."
        ;;
    restart)
        echo -n "Restarting: $NAME"
        stopapp
        sleep 1
        startapp
        echo "."
        ;;
    check)
        echo -n "Checking if the $NAME is running..."
        check_running
        echo "."
        ;;
    *)
    echo "Usage: $0 (start|stop|restart|check)"
    exit 1
    ;;
esac
