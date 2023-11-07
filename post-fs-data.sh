#!/system/bin/sh
MODDIR=${0%/*}
rm -f ${MODDIR}/src/start
rm -f ${MODDIR}/src/tailscaled.pid
rm -f ${MODDIR}/src/tailscaled.sock
