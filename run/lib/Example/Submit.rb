class Example
  class Submit
    attr_writer :c

    def page_start
      @results = ''
    end

    #def page_get
    #def page_post
    def page_import
      @c.validation = true
    end

    def foo
      @results << 'foo is called.'
    end
    gluon_export :foo

    def bar
      @results << 'bar is called.'
    end
    gluon_export :bar

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
