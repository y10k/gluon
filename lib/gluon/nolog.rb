# -*- coding: utf-8 -*-
# = gluon - simple web application framework
# == license
#   :include:../LICENSE
#

require 'singleton'

module Gluon
  # = fake logger
  class NoLogger
    # for ident(1)
    CVS_ID = '$Id$'

    include Singleton

    def debug?
      false
    end

    def debug(messg)
    end

    def info(messg)
    end

    def warn(messg)
    end

    def error(messg)
    end

    def fatal(messg)
    end

    def close
    end
  end
end


# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
