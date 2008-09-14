class Example
  class Value
    include Gluon::Controller
    include Gluon::ERBView

    #def page_get
    def page_import
    end

    def hello
      'Hello world.'
    end

    def emphasis_hello
      '<em>Hello world.</em>'
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
