class Example
  class Select
    attr_writer :c

    def page_start
      @fruit_list = %w[ apple banana orange ]
      @planet_list = %w[ Mercury Venus Earth Mars Jupiter Saturn Uranus Neptune ]
      @foo = 'apple'
      @bar = %w[ Earth Jupiter ]
    end

    attr_reader :fruit_list
    attr_reader :planet_list
    gluon_accessor :foo
    gluon_accessor :bar

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
