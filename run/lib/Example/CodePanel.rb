class Example
  class CodePanel
    include Dispatch
    include Gluon::Controller
    include Gluon::ERBView

    gluon_path_filter EXAMPLE_FILTER

    attr_reader :key

    def filename
      File.basename(@code)
    end

    def code
      IO.read(@code)
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
