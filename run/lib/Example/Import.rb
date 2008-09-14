class Example
  class Subpage
    include Gluon::Controller
    include Gluon::ERBView

    def initialize(message='Hello world.')
      @message = message
    end

    #def page_get
    def page_import
    end

    attr_reader :message
  end

  class Import
    include Gluon::Controller
    include Gluon::ERBView

    #def page_get
    def page_import
    end

    def subpage_by_class
      Subpage
    end

    def subpage_by_object
      Subpage.new
    end

    def subpage_with_params
      Subpage.new('foo')
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
