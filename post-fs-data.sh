#!/bin/sh
MODDIR=${0%/*}

echo > "${MODDIR}/src/tailscaled.pid"
rm ${MODDIR}/src/tailscaled.sock
rm ${MODDIR}/src/start.sock
