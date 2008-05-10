class Example
  class Header
    include Dispatch

    attr_writer :c

    def example?
      @c.curr_page == ExamplePanel
    end

    def example
      return ExamplePanel, :path_info => @c.path_info
    end

    def code?
      @c.curr_page == CodePanel
    end

    def code
      return CodePanel, :path_info => @c.path_info
    end

    def view?
      @c.curr_page == ViewPanel
    end

    def view
      return ViewPanel, :path_info => @c.path_info
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
