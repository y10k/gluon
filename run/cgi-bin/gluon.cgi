#!/bin/sh
# -*- coding: utf-8 -*-

BASE_DIR="`dirname $0`/.."
CGI_ENV="$BASE_DIR/cgi.env"

if [ -f "$CGI_ENV" ]; then
  . "$CGI_ENV"
fi

exec rackup

# Local Variables:
# indent-tabs-mode: nil
# End:
