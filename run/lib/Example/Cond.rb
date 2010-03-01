# -*- coding: utf-8 -*-

class Example
  class Cond
    extend Gluon::Component

    def_page_encoding __ENCODING__

    # for Example::Menu and Example::Panel
    def self.description
      'cond'
    end

    def foo?
      true
    end
    gluon_cond :foo?
    gluon_cond_not :foo?

    def bar?
      false
    end
    gluon_cond :bar?
    gluon_cond_not :bar?
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
