class Example
  class Cond
    include Gluon::Controller
    include Gluon::ERBView

    #def page_get
    def page_import
    end

    def true_test
      true
    end

    def false_test
      false
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
