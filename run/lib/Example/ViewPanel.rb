class Example
  class ViewPanel
    include Dispatch

    attr_reader :key

    def view_page
      IO.read(@view)
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
