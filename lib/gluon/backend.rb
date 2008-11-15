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
  # these methods should be explicitly defined at included class.
  # * gluon_service_key
  # * gluon_service_get
  #
  module BackendServiceAdaptor
    def gluon_service_around_hook
      yield
    end

    def gluon_service_start
    end

    def gluon_service_end
    end
  end

  class BackendServiceManager
    # for ident(1)
    CVS_ID = '$Id$'

    NO_SERVICE = Struct.new(:__no_service__)

    def initialize
      @service_set = {}
    end

    def register(adaptor)
      key = adaptor.gluon_service_key
      if (@service_set.key? key) then
        raise "failed to register `#{adaptor.class}' at `#{key}' (already registerd `#{@service_set[key].class}')"
      end
      @service_set[key] = adaptor
      self
    end

    def apply_around_hook
      apply_around_hook_r(@service_set.values) { yield }
      self
    end

    def apply_around_hook_r(adaptors)
      if (adaptors.empty?) then
        yield
      else
        adaptors.shift.gluon_service_around_hook{
          apply_around_hook_r(adaptors) { yield }
        }
      end
      nil
    end
    private :apply_around_hook_r

    def setup
      @service_set.freeze
      if (@service_set.empty?) then
        @services = []
        @struct = NO_SERVICE
      else
        service_keys = []
        @services = []
        for key, adaptor in @service_set
          adaptor.gluon_service_start
          service_keys << key
          @services << adaptor.gluon_service_get
        end
        @struct = Struct.new(*service_keys)
      end
      self
    end

    def shutdown
      @service_set.each_value do |adaptor|
        adaptor.gluon_service_end
      end
      nil
    end

    def new_services
      @struct.new(*@services)
    end

    alias call new_services
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
