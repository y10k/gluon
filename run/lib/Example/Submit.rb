class Example
  class Submit
    attr_accessor :c

    def page_start
      @results = ''
      @example = @c.req['example'] # hack to dispatch example
    end

    def foo_action
      @results << 'foo is called.'
    end

    def bar_action
      @results << 'bar is called.'
    end

    def no_action?
      @results.empty?
    end

    attr_reader :results
    attr_reader :example        # hack to dispatch example
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
