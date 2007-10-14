class Example
  class Radio
    attr_accessor :c

    def page_start
      @example = @c.req['example'] # hack to dispatch example
      @foo = 'apple'
      @bar = 'Bob'
    end

    attr_reader :example	# hack to dispatch example
    attr_accessor :foo
    attr_accessor :bar

    def ok
      # nothing to do.
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
