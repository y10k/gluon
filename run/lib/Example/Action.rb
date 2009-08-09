# -*- conding: utf-8 -*-

class Example
  class Action
    extend Gluon::Component

    def self.page_encoding
      __ENCODING__
    end

    # for Example::Menu and Example::Panel
    def self.description
      'action'
    end

    def initialize
      @results = ''
    end

    def foo
      @results << 'foo is called.'
    end
    gluon_action :foo, :attrs => { 'target' => 'main' }

    def bar
      @results << 'bar is called.'
    end
    gluon_action :bar, :attrs => { 'target' => 'main' }

    def action?
      ! @results.empty?
    end
    gluon_cond :action?
    gluon_cond_not :action?

    gluon_value_reader :results
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
