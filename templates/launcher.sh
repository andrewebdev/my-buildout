#!/bin/sh
 
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
NAME=${control-script}
 
dev_start(){

    $CONTROLSCRIPT runfcgi \
        method=threaded \
        host=${opts:app_host} \
        port=${opts:fcgi_port} \
        daemonize=false \
        errorlog=$LOG_PATH/${control-script}_errors

}


startapp(){
    # Gunicorn
    $BIN_PATH/gunicorn_paster -D \
        -w ${opts:workers} \
        -p ${opts:pidfile} \
        --log-file=${:logfile} \
        ${:pasteini}

    # FastCGI
    # $CONTROLSCRIPT runfcgi \
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
        if [ `ps -u ${opts:username} | grep -i ${control-script} | wc -l` -lt 1 ]; then
            d_start
        fi
    else
        d_start
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
    rundev)
        echo -n "Running $NAME in development mode."
        startdev
        echo "."
        ;;
    *)
    echo "Usage: $0 (start|stop|restart|check|rundev)"
    exit 1
    ;;
esac
