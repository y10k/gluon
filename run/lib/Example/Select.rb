# -*- coding utf-8 -*-

class Example
  class Select
    extend Gluon::Component

    def_page_encoding __ENCODING__

    # for Example::Menu and Example::Panel
    def self.description
      'select'
    end

    def initialize
      @foo = 'Apple'
      @bar = %w[ Earth Jupiter ]
    end

    gluon_select_accessor :foo, %w[ Apple Banana Orange ], :autoid => true
    gluon_select_accessor :bar,
      %w[ Mercury Venus Earth Mars Jupiter Saturn Uranus Neptune ],
      :multiple => true, :autoid => true, :attrs => { 'size' => 5 }

    alias foo_value foo
    gluon_value :foo_value

    def bar_values
      @bar.join(', ')
    end
    gluon_value :bar_values

    def ok
      # nothing to do.
    end
    gluon_submit :ok
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
