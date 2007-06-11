require 'Example/dispatch'

class Example
  class ExamplePanel
    include Dispatch

    def example_page
      @class
    end
  end
end
