class Example
  class ExamplePanel
    include Dispatch

    gluon_path_filter EXAMPLE_FILTER

    def example
      @class
    end
    gluon_export :example, :accessor => true
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
