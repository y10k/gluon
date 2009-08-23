# -*- coding: utf-8 -*-

class Example
  class Passwd
    extend Gluon::Component

    def self.page_encoding
      __ENCODING__
    end

    # for Example::Menu and Example::Panel
    def self.description
      'passwd'
    end

    def initialize
      @foo = nil
    end

    gluon_passwd_accessor :foo, :attrs => { 'id' => 'foo' }

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
