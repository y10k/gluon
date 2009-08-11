# -*- coding: utf-8 -*-

class Example
  class Submit
    extend Gluon::Component

    def self.page_encoding
      __ENCODING__
    end

    # for Example::Menu and Example::Panel
    def self.description
      'submit'
    end

    def initialize
      @results = ''
    end

    gluon_value_reader :results

    def action?
      ! @results.empty?
    end
    gluon_cond :action?
    gluon_cond_not :action?

    def foo
      @results << 'foo is called.'
    end
    gluon_submit :foo, :value => 'foo'

    def bar
      @results << 'bar is called.'
    end
    gluon_submit :bar, :value => 'bar'
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
