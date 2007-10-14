class Example
  class Password
    attr_accessor :c

    def page_start
      @example = @c.req['example'] # hack to dispatch example
    end

    attr_reader :example	# hack to dispatch example
    attr_accessor :foo

    def ok
      # nothing to do.
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
