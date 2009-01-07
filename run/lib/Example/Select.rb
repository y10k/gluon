class Example
  class Select
    include Gluon::Controller
    include Gluon::ERBView

    FRUIT_LIST = %w[ apple banana orange ]
    PLANET_LIST = %w[ Mercury Venus Earth Mars Jupiter Saturn Uranus Neptune ]

    def page_start
      @foo = 'apple'
      @bar = %w[ Earth Jupiter ]
    end

    gluon_export_accessor :foo, :list => FRUIT_LIST
    gluon_export_accessor :bar,
      :list => PLANET_LIST,
      :multiple => true,
      :size => 5

    #def page_get
    #def page_post
    def page_import
      @c.validation = true
    end

    def action_path
      @c.class2path(ExamplePanel, Select)
    end

    def bar_join
      @bar.join(', ')
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
