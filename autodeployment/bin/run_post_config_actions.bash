#!/bin/bash

MYPATH_="${BASH_SOURCE[0]}"
MYDIR_="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${MYDIR_}/../../prepare/colors.bash"

configure_transmission="${MYDIR_}/../lib/configure_transmission.bash"

echo -e "${YELLOW}RUN: configure_transmission ${NC}"
. "$configure_transmission"

