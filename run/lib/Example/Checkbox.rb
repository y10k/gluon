class Example
  class Checkbox
    attr_accessor :c

    def page_start
      @example = @c.req['example'] # hack to dispatch example
      @foo = nil
      @bar = nil
      @baz = 't'
    end

    attr_reader :example	# hack to dispatch example
    attr_accessor :foo
    attr_accessor :bar
    attr_accessor :baz

    def ok
      # nothing to do.
    end

    def result_list
      results = []
      results << 'foo is checked.' if @foo
      results << 'bar is checked.' if @bar
      results << 'baz is checked.' if @baz
      results
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
