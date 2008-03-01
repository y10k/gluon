class Example
  class Submit
    attr_accessor :c

    def page_start
      @results = ''
    end

    def foo
      @results << 'foo is called.'
    end

    def bar
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
