# -*- coding: utf-8 -*-

class Example
  class Value
    extend Gluon::Component

    def self.page_encoding
      __ENCODING__
    end

    # for Example::Menu and Example::Panel
    def self.description
      'value'
    end

    def initialize
      @hello = 'Hello world.'
    end

    gluon_value_reader :hello

    def escaped_string
      "<em>#{@hello}</em>"
    end
    gluon_value :escaped_string

    def no_escaped_string
      "<em>#{@hello}</em>"
    end
    gluon_value :no_escaped_string, :escape => false
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
