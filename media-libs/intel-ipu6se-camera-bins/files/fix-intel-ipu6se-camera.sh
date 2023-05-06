#!/bin/bash
#
#
marker="/mnt/stateful_partition/.camera_fixed"

copy_libs()
{
    tmp="$(mktemp -d)"

    tar -xf /usr/share/intel-ipu6se-camera-bins.tar.gz -C $tmp

    [ -d /lib/firmware/intel ] || mkdir -p /lib/firmware/intel
    cp -f ${tmp}/ipu6-camera-bins-Chrome_jsl*/fw/ipu6se_fw.bin /lib/firmware/intel

    cp -f ${tmp}/ipu6-camera-bins-Chrome_jsl*/usr/lib64/*.so /usr/lib64/
    cp -f ${tmp}/ipu6-camera-bins-Chrome_jsl*/usr/lib64/*.a /usr/lib64/

    [ -d /usr/lib/lib64/pkgconfig ] || mkdir -p /usr/lib64/pkgconfig
    cp -rf ${tmp}/ipu6-camera-bins-Chrome_jsl*/usr/lib64/pkgconfig/*pc /usr/lib64/pkgconfig/

    rm "$tmp" -rf
}

grep -q avx /proc/cpuinfo

if [ $? -ne 0 ]; then
    rdev="$(rootdev)"
    p_redev="$(cat ${marker})"

    if [ "$rdev" != "$p_redev" ]; then
        mount -oremount,rw /
        copy_libs
        mount -oremount,ro /
        echo "$rdev" > "$marker"
        restart cros-camera
    fi
fi
