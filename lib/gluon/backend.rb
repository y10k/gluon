# -*- coding: utf-8 -*-
# = gluon - simple web application framework
# == license
#   :include:../LICENSE
#

module Gluon
  class BackendServiceManager
    # for ident(1)
    CVS_ID = '$Id$'

    NO_SERVICE = Struct.new(:__no_service__)

    def initialize
      @service_set = {}
    end

    def add(name, value, &block)
      @service_set[name] = [ value, block ]
      nil
    end

    def setup
      @service_set.freeze
      if (@service_set.empty?) then
        @services = []
        @struct = NO_SERVICE
      else
        @services = []
        service_keys = []
        for key, (value, finalizer) in @service_set
          @services << value
          service_keys << key
        end
        @struct = Struct.new(*service_keys)
      end
      nil
    end

    def shutdown
      @service_set.each_value do |value, finalizer|
        finalizer.call(value)
      end
      nil
    end

    def new_services
      @struct.new(*@services)
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
