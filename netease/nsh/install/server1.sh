#!/usr/bin/env bash

$(dirname $0)/server.sh
$(dirname $0)/GasRunner -p 1234 -n gas
