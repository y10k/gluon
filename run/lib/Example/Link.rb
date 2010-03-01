# -*- coding: utf-8 -*-

class Example
  class Link
    extend Gluon::Component

    def_page_encoding __ENCODING__

    # for Example::Menu and Example::Panel
    def self.description
      'link'
    end

    def root
      '/'
    end
    gluon_link :root, :attrs => { 'target' => '_top' }

    def welcom
      Welcom
    end
    gluon_link :welcom, :attrs => { 'target' => '_top' }

    def ruby_home
      'http://www.ruby-lang.org/'
    end
    gluon_link :ruby_home, :text => :description, :attrs => { 'target' => '_blank' }

    def description
      'Ruby Programming Language'
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
