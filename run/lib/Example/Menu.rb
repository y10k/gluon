class Example
  class Menu
    def page_start
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

    attr_reader :examples

    def page_get
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
