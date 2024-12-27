#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# API levels
PRODUCT_SHIPPING_API_LEVEL := 28

# Health
PRODUCT_PACKAGES += \
    android.hardware.health@2.1-impl \
    android.hardware.health@2.1-impl.recovery \
    android.hardware.health@2.1-service

# Overlays
PRODUCT_ENFORCE_RRO_TARGETS := *

# Product characteristics
PRODUCT_CHARACTERISTICS := nosdcard,watch

# Rootdir
PRODUCT_PACKAGES += \
    init.class_main.sh \
    init.mdm.sh \
    init.qcom.early_boot.sh \
    init.qcom.efs.sync.sh \
    init.qcom.post_boot.sh \
    init.qcom.sensors.sh \
    init.qcom.sh \
    init.qcom.usb.sh \
    init.qti.charger.sh \
    init.qti.qseecomd.sh \
    init.qti.syspart_fixup.sh \
    init.qti.wifi.sh \
    init.rsb.sh \

PRODUCT_PACKAGES += \
    fstab.hoki \
    init.common.rc \
    init.fossilcommon.rc \
    init.fs_postboot_script.rc \
    init.hoki.rc \
    init.msm.usb.configfs.rc \
    init.qcom.usb.rc \
    init.rsb.rc \
    init.target.rc \
    init.vendor.rc \

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH)

# Inherit the proprietary files
$(call inherit-product, vendor/fossil/hoki/hoki-vendor.mk)
