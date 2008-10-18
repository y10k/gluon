class Example
  class ExamplePanel
    include DispatchController

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
