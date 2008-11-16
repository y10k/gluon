class Example
  class Textarea
    include Gluon::Controller
    include Gluon::ERBView

    gluon_export_accessor :foo

    #def page_get
    #def page_post
    def page_import
      @c.validation = true
    end

    def action_path
      @c.class2path(Textarea, @c.path_info)
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
