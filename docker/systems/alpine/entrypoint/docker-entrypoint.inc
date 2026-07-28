#!/bin/bash

export PGDATA='/var/lib/postgresql/data'
POSTGRESQL_USER='postgres'
BACULA_USER='bacula'

function stop_bacula_dir()
{
    /etc/bacula/scripts/bacula-ctl-dir stop
}

function start_bacula_sd()
{
    /etc/bacula/scripts/bacula-ctl-sd start
}

function stop_bacula_sd()
{
    /etc/bacula/scripts/bacula-ctl-sd stop
}

function start_bacula_fd()
{
    /etc/bacula/scripts/bacula-ctl-fd start
}

function stop_bacula_fd()
{
    /etc/bacula/scripts/bacula-ctl-fd stop
}

function start_php_fpm()
{
    php-fpm85
}

function stop_php_fpm()
{
    kill `pidof php-fpm85`
}
