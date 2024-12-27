#! /vendor/bin/sh

# Copyright (c) 2012-2013, 2016-2018, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of The Linux Foundation nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

function configure_zram_parameters() {
    MemTotalStr=`cat /proc/meminfo | grep MemTotal`
    MemTotal=${MemTotalStr:16:8}

    # Zram disk - 75% for Go devices.
    # For 512MB Go device, size = 384MB, set same for Non-Go.
    # For 1GB Go device, size = 768MB, set same for Non-Go.
    # For >=2GB Non-Go device, size = 1GB
    # And enable lz4 zram compression for 4100 targets.

    echo lz4 > /sys/block/zram0/comp_algorithm

    echo 1 > /sys/block/zram0/use_dedup
    if [ $MemTotal -le 524288 ]; then
        echo lz4 > /sys/block/zram0/comp_algorithm
        echo 402653184 > /sys/block/zram0/disksize
    elif [ $MemTotal -le 1048576 ]; then
        echo lz4 > /sys/block/zram0/comp_algorithm
        echo 805306368 > /sys/block/zram0/disksize
    else
        # Set Zram disk size=1GB for >=2GB Non-Go targets.
        echo 1073741824 > /sys/block/zram0/disksize
    fi
    mkswap /dev/block/zram0
    swapon /dev/block/zram0 -p 32758
}

function configure_read_ahead_kb_values() {
    MemTotalStr=`cat /proc/meminfo | grep MemTotal`
    MemTotal=${MemTotalStr:16:8}

    # Set 128 for <= 3GB &
    # set 512 for >= 4GB targets.
    if [ $MemTotal -le 3145728 ]; then
        echo 128 > /sys/block/mmcblk0/bdi/read_ahead_kb
        echo 128 > /sys/block/mmcblk0/queue/read_ahead_kb
        echo 128 > /sys/block/mmcblk0rpmb/bdi/read_ahead_kb
        echo 128 > /sys/block/mmcblk0rpmb/queue/read_ahead_kb
        echo 128 > /sys/block/dm-0/queue/read_ahead_kb
        echo 128 > /sys/block/dm-1/queue/read_ahead_kb
        echo 128 > /sys/block/dm-2/queue/read_ahead_kb
    else
        echo 512 > /sys/block/mmcblk0/bdi/read_ahead_kb
        echo 512 > /sys/block/mmcblk0/queue/read_ahead_kb
        echo 512 > /sys/block/mmcblk0rpmb/bdi/read_ahead_kb
        echo 512 > /sys/block/mmcblk0rpmb/queue/read_ahead_kb
        echo 512 > /sys/block/dm-0/queue/read_ahead_kb
        echo 512 > /sys/block/dm-1/queue/read_ahead_kb
        echo 512 > /sys/block/dm-2/queue/read_ahead_kb
    fi
}
function configure_memory_parameters_4_14() {
    # Disable Adaptive LMK
    echo 1 > /sys/module/lowmemorykiller/parameters/enable_lmk
    echo 0 > /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk
    echo 1 > /sys/module/process_reclaim/parameters/enable_process_reclaim
    # Enable oom_reaper for Go devices
    if [ -f /proc/sys/vm/reap_mem_on_sigkill ]; then
       echo 1 > /proc/sys/vm/reap_mem_on_sigkill
    fi
    echo 16384 > /sys/module/lowmemorykiller/parameters/vmpressure_file_min
    echo 1 > /sys/module/lowmemorykiller/parameters/oom_reaper
    # Set allocstall_threshold to 0 for all targets.
    # Set swappiness to 100 for all targets
    echo 0 > /sys/module/vmpressure/parameters/allocstall_threshold
    echo 100 > /proc/sys/vm/swappiness

    # Disable wsf for all targets beacause we are using efk.
    # wsf Range : 1..1000 So set to bare minimum value 1.
    #echo 1 > /proc/sys/vm/watermark_scale_factor
    # configure_zram_parameters

    configure_read_ahead_kb_values
}

function configure_memory_parameters_4_9() {
    # Set Memory parameters.
    #
    # Set per_process_reclaim tuning parameters
    # All targets will use vmpressure range 50-70,
    # All targets will use 512 pages swap size.
    #
    # Set Low memory killer minfree parameters
    # 32 bit Non-Go, all memory configurations will use 15K series
    # 32 bit Go, all memory configurations will use uLMK + Memcg
    # 64 bit will use Google default LMK series.
    #
    # Set ALMK parameters (usually above the highest minfree values)
    # vmpressure_file_min threshold is always set slightly higher
    # than LMK minfree's last bin value for all targets. It is calculated as
    # vmpressure_file_min = (last bin - second last bin ) + last bin
    #
    # Set allocstall_threshold to 0 for all targets.
    #

    MemTotalStr=`cat /proc/meminfo | grep MemTotal`
    MemTotal=${MemTotalStr:16:8}

    # Set parameters for 32-bit Go targets.

    # Read adj series and set adj threshold for PPR and ALMK.
    # This is required since adj values change from framework to framework.
    adj_series=`cat /sys/module/lowmemorykiller/parameters/adj`
    adj_1="${adj_series#*,}"
    set_almk_ppr_adj="${adj_1%%,*}"

    # PPR and ALMK should not act on HOME adj and below.
    # Normalized ADJ for HOME is 6. Hence multiply by 6
    # ADJ score represented as INT in LMK params, actual score can be in decimal
    # Hence add 6 considering a worst case of 0.9 conversion to INT (0.9*6).
    # For uLMK + Memcg, this will be set as 6 since adj is zero.
    set_almk_ppr_adj=$(((set_almk_ppr_adj * 6) + 6))
    echo $set_almk_ppr_adj > /sys/module/lowmemorykiller/parameters/adj_max_shift

    # Enable KLMK for sdx429.
    echo 1 > /sys/module/lowmemorykiller/parameters/enable_lmk

    echo "15360,19200,23040,26880,34415,43737" > /sys/module/lowmemorykiller/parameters/minfree
    echo 53059 > /sys/module/lowmemorykiller/parameters/vmpressure_file_min

    # Enable adaptive LMK for all targets &
    # use Google default LMK series for all 64-bit targets >=2GB.
    echo 1 > /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk

    # Set PPR parameters
    if [ -f /sys/devices/soc0/soc_id ]; then
        soc_id=`cat /sys/devices/soc0/soc_id`
    else
        soc_id=`cat /sys/devices/system/soc/soc0/id`
    fi
    #Set PPR parameters for all other targets.
    echo $set_almk_ppr_adj > /sys/module/process_reclaim/parameters/min_score_adj
    # Enable reclame memory to avoid crashed
    echo 1 > /sys/module/process_reclaim/parameters/enable_process_reclaim
    echo 50 > /sys/module/process_reclaim/parameters/pressure_min
    echo 70 > /sys/module/process_reclaim/parameters/pressure_max
    echo 30 > /sys/module/process_reclaim/parameters/swap_opt_eff
    echo 512 > /sys/module/process_reclaim/parameters/per_swap_size

    # Set allocstall_threshold to 0 for all targets.
    # Set swappiness to 100 for all targets
    echo 0 > /sys/module/vmpressure/parameters/allocstall_threshold
    echo 100 > /proc/sys/vm/swappiness

    configure_zram_parameters

    # configure_read_ahead_kb_values

}

function enable_memory_features()
{
    MemTotalStr=`cat /proc/meminfo | grep MemTotal`
    MemTotal=${MemTotalStr:16:8}

    if [ $MemTotal -le 2097152 ]; then
        #Enable B service adj transition for 2GB or less memory
        setprop ro.vendor.qti.sys.fw.bservice_enable true
        setprop ro.vendor.qti.sys.fw.bservice_limit 5
        setprop ro.vendor.qti.sys.fw.bservice_age 5000

        #Enable Delay Service Restart
        setprop ro.vendor.qti.am.reschedule_service true
    fi
}

# For target 8937/sda429w/sdm429w
if [ -f /sys/devices/soc0/soc_id ]; then
    soc_id=`cat /sys/devices/soc0/soc_id`
else
    soc_id=`cat /sys/devices/system/soc/soc0/id`
fi

if [ -f /sys/devices/soc0/hw_platform ]; then
    hw_platform=`cat /sys/devices/soc0/hw_platform`
else
    hw_platform=`cat /sys/devices/system/soc/soc0/hw_platform`
fi
if [ -f /sys/devices/soc0/platform_subtype_id ]; then
    platform_subtype_id=`cat /sys/devices/soc0/platform_subtype_id`
fi

# Apply settings for sdm429/sda429/sdm439/sda439

kernel_version=`uname -r`
kernel_version_major=`echo $kernel_version | cut -f1 -d"."`
kernel_version_minor=`echo $kernel_version | cut -f2 -d"."`

if [ $kernel_version_major -eq '4' ]; then
    # configure schedutil governor settings
    echo 1 > /sys/devices/system/cpu/cpu0/online
    echo "schedutil" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
    # Kernel version 4.14
    if [ $kernel_version_minor -eq '14' ]; then
        for latfloor in /sys/devices/platform/soc/*cpu-ddr-latfloor*/devfreq/*cpu-ddr-latfloor*
        do
            echo "compute" > $latfloor/governor
            echo 10 > $latfloor/polling_interval
        done

        for devfreq_gov in /sys/class/devfreq/*qcom,cpubw*
        do
            echo "bw_hwmon" > $devfreq_gov/governor
            echo 68 > $devfreq_gov/bw_hwmon/io_percent
            echo 20 > $devfreq_gov/bw_hwmon/hist_memory
            echo 80 > $devfreq_gov/bw_hwmon/down_thres
            echo 30 > $devfreq_gov/bw_hwmon/guard_band_mbps
        done

        for gpu_bimc_io_percent in /sys/class/devfreq/soc:qcom,gpubw/bw_hwmon/io_percent
        do
           echo 40 > $gpu_bimc_io_percent
        done
        # Apply settings for sdm429/sda429
        echo 0 > /sys/devices/system/cpu/cpufreq/schedutil/up_rate_limit_us
        echo 1000 > /sys/devices/system/cpu/cpufreq/schedutil/down_rate_limit_us
        #set the hispeed_freq
        echo 1305600 > /sys/devices/system/cpu/cpufreq/schedutil/hispeed_freq
        echo 90 > /sys/devices/system/cpu/cpufreq/schedutil/hispeed_load
        echo 960000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
        # Set Memory parameters
        configure_memory_parameters_4_14

    fi
    # Kernel version 4.9
    if [ $kernel_version_minor -eq '9' ]; then
        for cpubw in /sys/class/devfreq/*qcom,mincpubw*
        do
            echo "powersave" > $cpubw/governor
        done

        for cpubw in /sys/class/devfreq/*qcom,cpubw*
        do
            echo "cpufreq" > $cpubw/governor
            echo 20 > $cpubw/bw_hwmon/io_percent
            echo 30 > $cpubw/bw_hwmon/guard_band_mbps
        done

        for gpu_bimc_io_percent in /sys/class/devfreq/soc:qcom,gpubw/bw_hwmon/io_percent
        do
            echo 40 > $gpu_bimc_io_percent
        done

       # Apply settings for sdm429/sda429
       echo 0 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/rate_limit_us
       #set the hispeed_freq
       echo 1305600 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/hispeed_freq
       echo 80 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/hispeed_load
       echo 960000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
       # Set Memory parameters
       configure_memory_parameters_4_9
    fi
fi

# disable sched_boost
echo 0 > /proc/sys/kernel/sched_boost

# Enable low power modes
echo N > /sys/module/lpm_levels/parameters/sleep_disabled


chown -h system /sys/devices/system/cpu/cpufreq/ondemand/sampling_rate
chown -h system /sys/devices/system/cpu/cpufreq/ondemand/sampling_down_factor
chown -h system /sys/devices/system/cpu/cpufreq/ondemand/io_is_busy

# Post-setup services
setprop vendor.post_boot.parsed 1

# Let kernel know our image version/variant/crm_version
if [ -f /sys/devices/soc0/select_image ]; then
    image_version="10:"
    image_version+=`getprop ro.build.id`
    image_version+=":"
    image_version+=`getprop ro.build.version.incremental`
    image_variant=`getprop ro.product.name`
    image_variant+="-"
    image_variant+=`getprop ro.build.type`
    oem_version=`getprop ro.build.version.codename`
    echo 10 > /sys/devices/soc0/select_image
    echo $image_version > /sys/devices/soc0/image_version
    echo $image_variant > /sys/devices/soc0/image_variant
    echo $oem_version > /sys/devices/soc0/image_crm_version
fi

# Parse misc partition path and set property
misc_link=$(ls -l /dev/block/bootdevice/by-name/misc)
real_path=${misc_link##*>}
setprop persist.vendor.mmi.misc_dev_path $real_path

