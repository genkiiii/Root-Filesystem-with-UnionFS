#!/bin/sh
# Author:genki
#

. /etc/rfsync.conf

REMOUNTS=""

clean_exit() {
    local mounts="$1" rc=0 d="" lowerdir="" mp=""
    for d in ${mounts}; do
	if mountpoint ${d} >/dev/null; then
	    umount ${d} || rc=1
	    fi
	done
    for mp in $REMOUNTS; do
	mount -o remount,ro "${mp}" ||
	error "Note that [${mp}] is still mounted read/write"
	done
    [ "$2" = "return" ] && return ${rc} || exit ${rc}
}


#lowerdir="/fsprotect/system"

recurse_mps=$(awk '$1 ~ /^\/dev\// && $2 ~ starts { print $2 }' \
    starts="^$lowerdir/" /proc/mounts)

mounts=
for d in proc run sys boot/firmware; do
    if ! mountpoint "${lowerdir}/${d}" >/dev/null; then
	mount -o bind "/${d}" "${lowerdir}/${d}" || fail "Unable to bind /${d}"
	mounts="$mounts $lowerdir/$d"
	trap "clean_exit \"${mounts}\" || true" EXIT HUP INT QUIT TERM   
	fi
done

for mp in "$lowerdir" $recurse_mps; do
    mount -o remount,rw "${mp}" &&
    REMOUNTS="$mp $REMOUNTS" ||
    fail "Unable to remount [$mp] writable"
done

echo "Chrooting into [${lowerdir}]"

chroot ${lowerdir} "$@"

clean_exit "${mounts}" "return"
trap "" EXIT HUP INT QUIT TERM
