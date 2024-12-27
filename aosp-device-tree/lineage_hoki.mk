#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit some common Lineage stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

# Inherit from hoki device
$(call inherit-product, device/fossil/hoki/device.mk)

PRODUCT_DEVICE := hoki
PRODUCT_NAME := lineage_hoki
PRODUCT_BRAND := Fossil
PRODUCT_MODEL := Hoki
PRODUCT_MANUFACTURER := fossil

PRODUCT_GMS_CLIENTID_BASE := android-fossil

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRIVATE_BUILD_DESC="hoki-user 9 PFHD.211201.017 1648389875849 release-keys"

BUILD_FINGERPRINT := Fossil/hoki/hoki:9/PFHD.211201.017/1648389875849:user/release-keys
