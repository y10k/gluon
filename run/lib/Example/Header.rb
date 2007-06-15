class Example
  class Header
    include Dispatch

    attr_accessor :c

    def example?
      @c.curr_page == ExamplePanel
    end

    def example
      return ExamplePanel, :query => { 'example' => @key }
    end

    def code?
      @c.curr_page == CodePanel
    end

    def code
      return CodePanel, :query => { 'example' => @key }
    end

    def view?
      @c.curr_page == ViewPanel
    end

    def view
      return ViewPanel, :query => { 'example' => @key }
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
