require 'Example/Dispatch'

class Example
  class ViewPanel
    include Dispatch

    def view_page
      IO.read(@view)
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
