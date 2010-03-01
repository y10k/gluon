# -*- coding: utf-8 -*-

class Example
  class Submit
    extend Gluon::Component

    def_page_encoding __ENCODING__

    # for Example::Menu and Example::Panel
    def self.description
      'submit'
    end

    def initialize
      @result = nil
    end

    gluon_value_reader :result

    def action?
      @result != nil
    end
    gluon_cond :action?
    gluon_cond_not :action?

    def foo
      @result = 'foo is called.'
    end
    gluon_submit :foo, :value => 'foo'

    def bar
      @result = 'bar is called.'
    end
    gluon_submit :bar, :value => 'bar'
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
