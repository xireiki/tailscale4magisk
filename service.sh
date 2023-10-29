#!/bin/sh
MODDIR=${0%/*}
DES="使用 tailscale 进行组网，不与 tun 冲突，可同连接 tun 代理，tproxy 自行测试。"
listen="localhost:8088"
export PWD="${MODDID}/src"
cd "${MODDIR}/src"
SERVICE_NAME="tailscale"
PKGVAR="${MODDIR}/src"
PID_FILE="${PKGVAR}/tailscaled.pid"
LOG_FILE="${PKGVAR}/tailscaled.stdout.log"
STATE_FILE="${PKGVAR}/tailscaled.state"
SOCKET_FILE="${PKGVAR}/tailscaled.sock"

SERVICE_COMMAND="${MODDIR}/bin/tailscaled --state=${STATE_FILE} --socket=${SOCKET_FILE}"

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

start_daemon() {
  local ts=$(date --iso-8601=second)
  echo "${ts} Starting ${SERVICE_NAME} with: ${SERVICE_COMMAND}" >${LOG_FILE}
  STATE_DIRECTORY=${PKGVAR} ${SERVICE_COMMAND} 2>&1 | sed -u '1,200p;201s,.*,[further tailscaled logs suppressed],p;d' >>${LOG_FILE} &
  # We pipe tailscaled's output to sed, so "$!" retrieves the PID of sed not tailscaled.
  # Use jobs -p to retrieve the PID of the most recent process group leader.
  jobs -p >"${PID_FILE}"
}

daemon_status() {
  if [ -r "${PID_FILE}" ]; then
    local PID=$(cat "${PID_FILE}")
    if ps -o pid -p ${PID} > /dev/null; then
        return
    fi
    rm -f "${PID_FILE}" >/dev/null
  fi
  return 1
}

wait_until_login

if [ -e "${MODDIR}/src/start.sock" ]; then
  exit
else
  touch "${MODDIR}/src/start.sock"
fi

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

if [ -x "${MODDIR}/bin/tailscaled" ]; then
  if [ -x "${MODDIR}/bin/start-stop-status" ]; then
    ${MODDIR}/bin/start-stop-status start
  fi
  sleep 5
  if [ -z "$(pidof tailscaled)" ]; then
    nohup ${MODDIR}/bin/tailscaled --state="${MODDIR}/src/tailscaled.state" > ${LOG_FILE} &
  fi
else
  sed -i "6cdescription=[tailscaled 核心不存在]${DES}" ${MODDIR}/module.prop
  exit 1
fi

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
  if [ -z "$(pidof tailscaled)" ]; then
    status=0
  fi
  sleep 1
done

if [ -z "$(pidof tailscaled)" ]; then
  sed -i "6cdescription=[核心启动失败]${DES}" ${MODDIR}/module.prop
else
  sed -i "6cdescription=[管理地址:${listen},已登录]${DES}" ${MODDIR}/module.prop
fi
