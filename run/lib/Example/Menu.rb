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
            ex = DispatchController::EXAMPLES[self]
            return ExamplePanel,
              :path_args => [ ex[:class] ], :text => ex[:title]
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
