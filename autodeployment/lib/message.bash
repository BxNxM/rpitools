#!/bin/bash

function _msg_() {
    local msg="$1"
    echo -e "$(date '+%Y.%m.%d %H:%M:%S') ${BLUE}[ $_msg_title ]${NC} - $msg"
}
