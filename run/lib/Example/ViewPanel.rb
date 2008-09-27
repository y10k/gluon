class Example
  class ViewPanel
    include Dispatch
    include Gluon::Controller
    include Gluon::ERBView

    gluon_path_filter EXAMPLE_FILTER

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
