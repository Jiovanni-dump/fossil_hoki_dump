#!/system/bin/sh
#
# Copyright (c) 2019-2021 Fossil Group, Inc.
# All Rights Reserved.
# Confidential and Proprietary - Fossil Group, Inc.
#
# This script will help to free up /userdata partition
#

BIN_DIR="/system/bin"

LOG="${BIN_DIR}/log"
CUT="${BIN_DIR}/cut"
PM="${BIN_DIR}/pm"

SETPROP="${BIN_DIR}/setprop"
GETPROP="${BIN_DIR}/getprop"

PRODUCT_NAME_PROP="ro.product.name"

FOSSIL_POSTBOOT_CLEANUP_PROP="persist.vendor.fossil.postboot_cleanup.enable"
SYSTEM_RETAILMODE_PROP="sys.cw_retail_mode"

BOOTMODE_FLAG_PATH="/persist/preoem/unified_boot_mode"

DEBUG_TAG="FOSSIL_CLEANUP"

LIST_ENABLED_PKG_ROW=" com.google.android.clockwork.leswitch" 

LIST_ENABLED_PKG_LE=" com.google.android.apps.translate" 

LIST_ENABLED_PKG="" 
LIST_ENABLED_PKG+=" com.google.android.apps.wearable.retailattractloop" 
LIST_ENABLED_PKG+=" com.android.providers.blockednumber" 
LIST_ENABLED_PKG+=" com.android.managedprovisioning" 
LIST_ENABLED_PKG+=" com.fossil.wearables.tos"

logi ()
{
        ${LOG} -t "${DEBUG_TAG}" -p i "${1}"
}

loge ()
{
        ${LOG} -t "${DEBUG_TAG}" -p e "${1}"
}

_detecting_retailmode_()
{
	# Waiting for sys.cw_retail_mode
	sleep 10
	IN_RETAILMODE=$(${GETPROP} ${SYSTEM_RETAILMODE_PROP})
	if [ "${IN_RETAILMODE}" == "1" ]; then
		logi "Nothing to do in Retail mode."
		exit 0
	fi
}

_detecting_bootmode_()
{
	PRODUCT_NAME=$(${GETPROP} ${PRODUCT_NAME_PROP})
	if [ -z ${PRODUCT_NAME} ]; then
		loge "Detecting bootmode was failured."
	else
		logi "Product name: ${PRODUCT_NAME}"
		case "${PRODUCT_NAME}" in
		        *"_sw")	logi "Detected bootmode: LE"
				LIST_ENABLED_PKG+=${LIST_ENABLED_PKG_LE};;
			*)	logi "Detecting bootmode: ROW"
				LIST_ENABLED_PKG+=${LIST_ENABLED_PKG_ROW};;
		esac
	fi
}

_clean_unused_pkgs_()
{
	logi "Start FS Postboot Script ..."

	# Disable packages
	for ENABLED_PKG in ${LIST_ENABLED_PKG}
	do
		# Check if the package exists first and only then disable it.
		PKG=$(${PM} list package ${ENABLED_PKG} | ${CUT} -f2 -d":")
		if [ "${PKG}" == "${ENABLED_PKG}" ]; then
			logi "Disabling package: ${ENABLED_PKG}"
			eval "${PM} disable --user 0 ${ENABLED_PKG}"
			LIST_PKG+=" ${ENABLED_PKG}"
		fi
	done

	# Collecting packaged were disabled by clockwork.
	LIST_PKG=$(${PM} list packages --user 0 -d | ${CUT} -d ":" -f2)

	logi "Waiting 120 seconds for onboarding process completing ..."
	sleep 120

	# Uninstalling and clear
	for PKG in ${LIST_PKG}
	do
		logi "Re-disabling/Uninstalling/Cleaning package: ${PKG}"
		eval "${PM} disable --user 0 ${PKG}"
		eval "${PM} uninstall --user 0 ${PKG}"
		eval "${PM} clear --user 0 ${PKG}"
	done

	logi "Clear the property ${FOSSIL_POSTBOOT_CLEANUP_PROP}"
	${SETPROP} ${FOSSIL_POSTBOOT_CLEANUP_PROP} 0
	if [ $? != 0 ]; then
		loge "Cleaning Fossil free-up flag was failured!"
	fi

	logi "FS Postboot Script is completed."
}

_detecting_retailmode_

# Update LIST_ENABLED_PKG based on bootmode of device.
_detecting_bootmode_

_clean_unused_pkgs_

exit 0
