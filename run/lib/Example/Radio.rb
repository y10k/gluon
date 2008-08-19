class Example
  class Radio
    attr_writer :c

    def page_start
      @foo = 'apple'
      @bar = 'Bob'
    end

    gluon_accessor :foo
    gluon_accessor :bar

    def ok
      # nothing to do.
    end
    gluon_export :ok
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
