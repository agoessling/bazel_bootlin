#!/bin/bash

NAME=$(basename "$0")

readarray -d - -t ELEMENTS <<< ${NAME}

# Bootlin isn't consistent with linux on x86_64 name.
if [ ${ELEMENTS[0]} = "x86" ] && [ ${ELEMENTS[1]} = "64" ]; then
  ARCH_NAME_BIN="x86_64"
else
  ARCH_NAME_BIN=${ELEMENTS[0]}
fi

BINDIR="external/${NAME::-${#ELEMENTS[-1]}}/bin"
TOOL_NAME="${ARCH_NAME_BIN}-buildroot-linux-gnu-${ELEMENTS[-1]::-1}.br_real"

EXECUTABLE="${BINDIR}/${TOOL_NAME}"

exec ${EXECUTABLE} $@
