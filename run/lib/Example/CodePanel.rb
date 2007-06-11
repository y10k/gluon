require 'Example/dispatch'

class Example
  class CodePanel
    include Dispatch

    def code_page
      IO.read(@code)
    end
  end
end
