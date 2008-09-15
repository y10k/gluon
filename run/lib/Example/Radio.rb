class Example
  class Radio
    include Gluon::Controller
    include Gluon::ERBView

    def page_start
      @foo = 'apple'
      @bar = 'Bob'
    end

    gluon_export_accessor :foo
    gluon_export_accessor :bar

    #def page_get
    #def page_post
    def page_import
      @c.validation = true
    end

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
