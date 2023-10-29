#!/sbin/sh

if [ "${ARCH}" != "arm64" ] ; then
  abort "- 不支持的架构，本模块只支持 arm64 架构的设备"
fi

if [ -f "/data/adb/modules/tailscale/src/tailscale.state" ]; then
  ui_print "检测到 state，正在保存"
  cp "/data/adb/modules/tailscale/src/tailscale.state" ${MODPATH}/src
fi

