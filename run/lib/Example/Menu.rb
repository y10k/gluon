class Example
  class Menu
    def initialize
      @examples = []
      for key in Dispatch::EXAMPLE_KEYS
        key = key.dup

        class << key
          def example
            return Example::ExamplePanel,
              :path_info => "/#{self}",
              :text => Example::Dispatch::EXAMPLES[self][:title]
          end
        end

        @examples << key
      end
    end

    def page_get
    end

    attr_reader :examples
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
