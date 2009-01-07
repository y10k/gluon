class Example
  class Header
    include Gluon::Controller
    include Gluon::ERBView

    def initialize(example)
      @example = example
    end

    def page_import
    end

    def example?
      @c.curr_page == ExamplePanel
    end

    def example
      return ExamplePanel, :path_args => [ @example ]
    end

    def code?
      @c.curr_page == CodePanel
    end

    def code
      return CodePanel, :path_args => [ @example ]
    end

    def view?
      @c.curr_page == ViewPanel
    end

    def view
      return ViewPanel, :path_args => [ @example ]
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
