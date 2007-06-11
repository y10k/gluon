require 'Example/dispatch'

class Example
  class ViewPanel
    include Dispatch

    def view_page
      IO.read(@view)
    end
  end
end
