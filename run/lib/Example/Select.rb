class Example
  class Select
    include Gluon::Controller
    include Gluon::ERBView

    def page_start
      @fruit_list = %w[ apple banana orange ]
      @planet_list = %w[ Mercury Venus Earth Mars Jupiter Saturn Uranus Neptune ]
      @foo = 'apple'
      @bar = %w[ Earth Jupiter ]
    end

    attr_reader :fruit_list
    attr_reader :planet_list

    gluon_export_accessor :foo,
      :list => instance_method(:fruit_list)

    gluon_export_accessor :bar,
      :list => instance_method(:planet_list),
      :multiple => true,
      :size => 5

    #def page_get
    #def page_post
    def page_import
      @c.validation = true
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
