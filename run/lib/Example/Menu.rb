class Example
  class Menu
    include Gluon::Controller
    include Gluon::ERBView

    def page_start
      @examples = []
      for key in DispatchController::EXAMPLE_KEYS
        key = key.dup

        class << key
          def example
            return Example::ExamplePanel,
              :path_info => "/#{self}",
              :text => Example::DispatchController::EXAMPLES[self][:title]
          end
        end

        @examples << key
      end
    end

    attr_reader :examples

    def page_get
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
