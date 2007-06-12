require 'Example/CodePanel'
require 'Example/Dispatch'
require 'Example/ExamplePanel'
require 'Example/ViewPanel'

class Example
  class Header
    include Dispatch

    attr_accessor :req

    def example?
      @req.env['gluon.curr_page'] == ExamplePanel
    end

    def example
      "/example/ex_panel?example=#{@key}"
    end

    def code?
      @req.env['gluon.curr_page'] == CodePanel
    end

    def code
      "/example/code_panel?example=#{@key}"
    end

    def view?
      @req.env['gluon.curr_page'] == ViewPanel
    end

    def view
      "/example/view_panel?example=#{@key}"
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
