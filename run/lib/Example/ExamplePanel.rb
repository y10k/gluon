# -*- coding: utf-8 -*-

require 'Example/Panel'

class Example
  class ExamplePanel < Panel
    def self.page_encoding
      __ENCODING__
    end

    def page_start
      super
      @example = @example_type.new
    end

    gluon_import_reader :example
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
