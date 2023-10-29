#!/bin/sh
MODDIR=${0%/*}
DES="使用 tailscale 进行组网，不与 tun 冲突，可同连接 tun 代理，tproxy 自行测试。"
listen="localhost:8088"
export PWD="${MODDID}/src"
cd "${MODDIR}/src"

wait_until_login(){
  # in case of /data encryption is disabled
  while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
  done

  sleep 5

  # we doesn't have the permission to rw "/sdcard" before the user unlocks the screen
  local test_file="/sdcard/Android/.TAILTEST"

  true > "$test_file"

  while [ ! -f "$test_file" ]; do
    true > "$test_file"
    sleep 1
  done

  rm "$test_file"
}

wait_until_login

chmod 700 ${MODDIR}/bin/tailscaled ${MODDIR}/bin/tailscale ${MODDIR}/bin/start-stop-status

if [ ! -e /dev/net/tun ]; then
  if [ ! -d /dev/net ]; then
    mkdir -m 755 /dev/net
  fi
  if [ -c /dev/tun ]; then
    ln -s /dev/tun /dev/net/tun
  else
    mknod /dev/net/tun c 10 200
    chmod 0755 /dev/net/tun
  fi
fi

if [ -x "${MODDIR}/bin/tailscaled" -a -x "${MODDIR}/bin/start-stop-status" ]; then
  ${MODDIR}/bin/start-stop-status start
else
  sed -i "6cdescription=[tailscaled 核心不存在]${DES}" ${MODDIR}/module.prop
  exit 1
fi

sleep 5

if ! ${MODDIR}/bin/start-stop-status status; then
  sed -i "6cdescription=[tailscaled 核心启动失败]${DES}" ${MODDIR}/module.prop
  exit 2
fi

if ! ${MODDIR}/bin/tailscale status; then
  sed -i "6cdescription=[管理地址:${listen},未登录]${DES}" ${MODDIR}/module.prop
elif ${MODDIR}/bin/tailscale status; then
  sed -i "6cdescription=[管理地址:${listen},已登录]${DES}" ${MODDIR}/module.prop
fi

nohup ${MODDIR}/bin/tailscale web > ${MODDIR}/src/web.log 2>&1 &

status=$(${MODDIR}/bin/tailscale status > /dev/null 2>&1; echo $?)
while [ "${status}" = "1" ]; do
  status=$(${MODDIR}/bin/tailscale status > /dev/null 2>&1; echo $?)
  sleep 1
done

sed -i "6cdescription=[管理地址:${listen},已登录]${DES}" ${MODDIR}/module.prop
