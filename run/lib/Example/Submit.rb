class Example
  class Submit
    def page_start
      @results = ''
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
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
