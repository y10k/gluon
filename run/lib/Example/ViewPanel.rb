class Example
  class ViewPanel
    include DispatchController

    def filename
      File.basename(@view)
    end

    def view
      IO.read(@view)
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
