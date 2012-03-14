#!/bin/bash

USER='techlive'
HOSTNAME='home'

cd $(dirname ${BASH_SOURCE[0]})

../dotploy.sh -d dotsrepo .
../dotploy.sh -r dotsrepo .
