#!/bin/bash

POSTGRESQL_USER='postgres'
BACULA_DBNAME='bacula'
BACULA_DBUSER='bacula'
BACULA_DBPASSWORD='bacula'
BACULA_USER='bacula'

function start_php_fpm()
{
    /etc/init.d/php8.4-fpm start
}

function stop_php_fpm()
{
    /etc/init.d/php8.4-fpm stop
}
