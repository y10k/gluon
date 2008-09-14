class Example
  class Link
    include Gluon::Controller
    include Gluon::ERBView

    #def page_get
    def page_import
    end

    def welcom
      Welcom
    end

    def description
      'return to welcom page.'
    end

    def ruby_home
      'http://www.ruby-lang.org/'
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
