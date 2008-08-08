class Example
  class ViewPanel
    include Dispatch

    gluon_path_filter EXAMPLE_FILTER

    def view
      IO.read(@view)
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
