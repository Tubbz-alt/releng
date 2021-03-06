#!/bin/bash

source common.sh

prepare_confs() {
  local flavor=$1
  local arch="arm64"
  local tarch="aarch64"
  local profile="default/linux/arm64/17.0/musl"
  [[ "${flavor}" == "hardened" ]] && profile="${profile}/hardened"

  for s in 1 2 3; do
    local cstage=stage${s}
    local p=$(( s - 1 ))
    [[ $p == 0 ]] && p=3
    local pstage=stage${p}

    cat stage.conf.template | \
      sed -e "s:\(^version_stamp.*$\):\1-${mydate}:" \
        -e "s:CSTAGE:${cstage}:g" \
        -e "s:PSTAGE:${pstage}:g" \
        -e "s:SARCH:${arch}:g" \
        -e "s:TARCH:${tarch}:g" \
        -e "s:FLAVOR:${flavor}:g" \
        -e "s:^profile\:.*:profile\: ${profile}:" \
        -e "s:MYCATALYST:$(pwd):g" \
        >  stage${s}-${arch}-musl-${flavor}.conf

    sed -i "/^portage_confdir/s:_hardfp::" \
      stage${s}-${arch}-musl-${flavor}.conf

    portage_confdir=$(grep portage_confdir stage${s}-${arch}-musl-${flavor}.conf \
      | sed -e 's/^.*:[ \t]*//')
    [[ ! -e ${portage_confdir} ]] && sed -i -e '/^portage_confdir/d' \
      stage${s}-${arch}-musl-${flavor}.conf
  done

  sed -i "/^chost/d" stage3-${arch}-musl-${flavor}.conf
}


main() {
  >zzz.log

  catalyst -s current | tee -a zzz.log >snapshot.log 2>snapshot.err

  for flavor in hardened vanilla; do
    prepare_confs ${flavor}
  done

  for flavor in hardened vanilla; do
    do_stages "arm64" ${flavor}
    [[ $? == 1 ]] && echo "FAILURE at ${arch} ${flavor} " | tee zzz.log
  done
}

main $1 &
