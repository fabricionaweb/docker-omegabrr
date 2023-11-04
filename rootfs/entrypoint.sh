#!/usr/bin/env sh

if [ "$#" -gt 0 ]; then
  # run (from /usr/local/bin) with the provided params
  exec omegabrr "$@"
else
  # if no params is provided, start s6 container as normal
  exec /init
fi
