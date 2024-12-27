#!/system/bin/sh
if ! applypatch -c EMMC:/dev/block/bootdevice/by-name/recovery:33554432:1bdc9e9204f8e2ca67e638837db537b144ffd0c9; then
  applypatch  EMMC:/dev/block/bootdevice/by-name/boot:33554432:5d5a1e65a81a32682f2c6ffda42f52b61df35352 EMMC:/dev/block/bootdevice/by-name/recovery 1bdc9e9204f8e2ca67e638837db537b144ffd0c9 33554432 5d5a1e65a81a32682f2c6ffda42f52b61df35352:/system/recovery-from-boot.p && log -t recovery "Installing new recovery image: succeeded" || log -t recovery "Installing new recovery image: failed"
else
  log -t recovery "Recovery image already installed"
fi
