# -*- coding: utf-8 -*-

class Example
  class Header
    extend Gluon::Component

    def self.page_encoding
      __ENCODING__
    end

    def initialize(req_res, example_type)
      @r = req_res
      @example_type = example_type
    end

    def example?
      @r.controller.is_a? ExamplePanel
    end
    gluon_cond :example?
    gluon_cond_not :example?

    def example
      return ExamplePanel, @example_type
    end
    gluon_link :example, :attrs => { 'target' => 'main' }

    def code?
      @r.controller.is_a? CodePanel
    end
    gluon_cond :code?
    gluon_cond_not :code?

    def code
      return CodePanel, @example_type
    end
    gluon_link :code, :attrs => { 'target' => 'main' }

    def view?
      @r.controller.is_a? ViewPanel
    end
    gluon_cond :view?
    gluon_cond_not :view?

    def view
      return ViewPanel, @example_type
    end
    gluon_link :view, :attrs => { 'target' => 'main' }
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
