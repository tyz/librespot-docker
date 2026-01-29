#!/bin/bash

set -e

: "${LIBRESPOT_NAME:=Librespot Docker}"
: "${LIBRESPOT_ZEROCONF_PORT:=30242}"
: "${LIBRESPOT_BACKEND:=alsa}"
: "${LIBRESPOT_DEVICE:=default}"
: "${LIBRESPOT_BITRATE:=320}"
: "${LIBRESPOT_FORMAT:=S32}"
: "${LIBRESPOT_INITIAL_VOLUME:=100}"

echo "Starting Librespot..."
echo "Name: $LIBRESPOT_NAME"
echo "Device: $LIBRESPOT_DEVICE"

exec /usr/local/bin/librespot \
    --name "$LIBRESPOT_NAME" \
    --backend "$LIBRESPOT_BACKEND" \
    --device "$LIBRESPOT_DEVICE" \
    --bitrate "$LIBRESPOT_BITRATE" \
    --format "$LIBRESPOT_FORMAT" \
    --initial-volume "$LIBRESPOT_INITIAL_VOLUME" \
    --zeroconf-port "$LIBRESPOT_ZEROCONF_PORT" \
    --disable-audio-cache \
    --enable-volume-normalisation \
    --normalisation-pregain 6 \
    --volume-ctrl linear \
    "$@"
