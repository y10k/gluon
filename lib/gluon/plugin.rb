# plugin

module Gluon
  class PluginMaker
    # for ident(1)
    CVS_ID = '$Id$'

    NO_PLUGIN = Struct.new(:__no_plugin__)

    def initialize
      @plugin_set = {}
    end

    def add(name, value)
      @plugin_set[name.to_sym] = value
      self
    end

    def setup
      @plugin_set.freeze
      if (@plugin_set.empty?) then
        @values = []
        @struct = NO_PLUGIN
      else
        @names = @plugin_set.keys
        @values = @names.map{|name| @plugin_set[name] }
        @struct = Struct.new(*@names)
      end
      self
    end

    def new_plugin
      @struct.new(*@values)
    end

    alias call new_plugin
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
