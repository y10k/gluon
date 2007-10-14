class Example
  class ViewPanel
    include Dispatch

    def view
      IO.read(@view)
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
