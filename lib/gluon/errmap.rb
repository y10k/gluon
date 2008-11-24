# = gluon - simple web application framework
#
# Author:: $Author$
# Date:: $Date$
# Revision:: $Revision$
#
# == license
#   :include:../LICENSE
#

module Gluon
  # = error handler mapping
  class ErrorMap
    # for ident(1)
    CVS_ID = '$Id$'

    def initialize
      @mapping = []
    end

    def error_handler(exception_type, page_type)
      unless (exception_type.is_a? Class) then
        raise ArgumentError, "not a exception_type class: #{exception_type}"
      end
      unless (exception_type <= Exception) then
        raise ArgumentError, "not a exception class: #{exception_type}"
      end
      unless (page_type.is_a? Class) then
        raise ArgumentError, "not a class: #{page_type}"
      end
      @mapping << [ exception_type, page_type ]
      nil
    end

    def setup
      @mapping = @mapping.sort_by{|exception_type, page_type|
        count = 0
        while (exception_type < Exception)
          exception_type = exception_type.superclass
          count += 1
        end

        -count
      }
      self
    end

    def lookup(exception_type)
      for ex_type, page_type in @mapping
        if (exception_type <= ex_type) then
          return page_type
        end
      end

      nil
    end

    def each
      for exception_type, page_type in @mapping
        yield(exception_type, page_type)
      end
      nil
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
