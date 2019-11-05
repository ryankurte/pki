#!/bin/bash
# Configuration helper


function configure_file {
    sed \
    -e "s|COUNTRY|$COUNTRY|g" \
    -e "s|STATE|$STATE|g" \
    -e "s|ORG|$ORG|g" \
    -e "s|ORG_UNIT|$ORG_UNIT|g" \
    -e "s|DOMAIN|$DOMAIN|g" \
    -e "s|EMAIL|$EMAIL|g" \
    -e "s|ROOT_NAME|$ROOT_NAME|g" \
    -e "s|INT_NAME|$INT_NAME|g" \
    -e "s|COMMON_NAME|$3|g" \
    -e "s|DIR|$DIR|g" \
	$1 > $2
}

