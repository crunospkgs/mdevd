#!/bin/sh

sh -c "sleep 1 && /usr/local/sbin/mdevd-coldplug" &

exec /usr/local/sbin/mdevd
