#!/system/bin/sh

# Copyright (c) 2019 Qualcomm Technologies, Inc.
# All Rights Reserved.
# Confidential and Proprietary - Qualcomm Technologies, Inc.

DEST_PATH="/data/vendor/qtee"
SRC_PATH="/data/misc/qsee"

if [[ ! -e "$DEST_PATH"/fido_session.dat ]]; then
  mv "$SRC_PATH"/fido_session.dat "$DEST_PATH/"
  restorecon -F /data/vendor/qtee/fido_session.dat
fi
