# -*- coding: utf-8 -*-

class Example
  class Textarea
    extend Gluon::Component

    def_page_encoding __ENCODING__

    # for Example::Menu and Example::Panel
    def self.description
      'textarea'
    end

    def initialize
      @foo = nil
    end

    gluon_textarea_accessor :foo, :attrs => { 'id' => 'foo', 'cols' => 80, 'rows' => 25 }

    alias form_value foo
    gluon_value :form_value

    def form_value?
      @foo != nil
    end
    gluon_cond :form_value?
    gluon_cond_not :form_value?

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
