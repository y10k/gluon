class Example
  class Checkbox
    include Gluon::Controller
    include Gluon::ERBView

    def page_start
      @foo = false
      @bar = false
      @baz = true
    end

    gluon_export_accessor :foo
    gluon_export_accessor :bar
    gluon_export_accessor :baz

    #def page_get
    #def page_post
    def page_import
      @c.validation = true
    end

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
