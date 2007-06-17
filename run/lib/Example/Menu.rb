class Example
  class Menu
    def initialize
      @examples = []
      for key in Dispatch::EXAMPLE_KEYS
        key = key.dup

        class << key
          def example
            return Example::ExamplePanel, :query => { 'example' => self }
          end

          def name
            self
          end
        end

        @examples << key
      end
    end

    attr_reader :examples
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
