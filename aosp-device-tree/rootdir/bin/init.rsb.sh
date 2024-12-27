#!/vendor/bin/sh

DEFAULT_RES=0x7e

echo "reading rsb persist data"
str=$(cat /mnt/vendor/persist/ots)
echo "str = $str"

calibrated=(${str:0:1})
echo "calibrated = $calibrated"

if [[ $calibrated = "0" ]]
  then
  res_x=(${DEFAULT_RES:2:2})
  echo "Not Calibrated. res_x=0x$res_x"
elif [[ $calibrated = "1" ]]
  then
  res_x=(${str:2:2})
  echo "Calibrated. res_x=0x$res_x"
else
  res_x=(${DEFAULT_RES:2:2})
  echo "Unknown status. res_x=0x$res_x"
fi

res_x=$((num=16#$res_x))
echo "res_x = $res_x(in DEC)"

echo "Write initial resolution..."
echo 2:7:$res_x > /sys/devices/platform/soc/soc:qcom,bg-rsb/enable
sleep 0.5
