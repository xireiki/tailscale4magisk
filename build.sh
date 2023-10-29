#!/bin/sh

if [ -z "$@" ]; then
  zip -r -o -X -ll tailscale_$(cat module.prop | grep 'version=' | awk -F '=' '{print $2}').zip ./ -x '.git/*' -x 'build.sh' -x '.github/*' -x 'tailscale.json'
else
  zip -r -o -X -ll tailscale_${1}.zip ./ -x '.git/*' -x 'build.sh' -x '.github/*' -x 'tailscale.json'
fi
