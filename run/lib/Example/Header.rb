class Example
  class Header
    include Dispatch

    attr_accessor :req

    def example?
      @req.env['gluon.curr_page'] == ExamplePanel
    end

    def example
      return ExamplePanel, :query => { 'example' => @key }
    end

    def code?
      @req.env['gluon.curr_page'] == CodePanel
    end

    def code
      return CodePanel, :query => { 'example' => @key }
    end

    def view?
      @req.env['gluon.curr_page'] == ViewPanel
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
