class Example
  class Checkbox
    attr_writer :c

    def page_start
      @foo = false
      @bar = false
      @baz = true
    end

    gluon_accessor :foo
    gluon_accessor :bar
    gluon_accessor :baz

    def ok
      # nothing to do.
    end
    gluon_export :ok

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
