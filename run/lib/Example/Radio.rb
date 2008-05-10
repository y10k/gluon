class Example
  class Radio
    attr_writer :c

    def page_start
      @foo = 'apple'
      @bar = 'Bob'
    end

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
