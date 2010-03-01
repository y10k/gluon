# -*- coding: utf-8 -*-

class Example
  class ErrorMessages
    extend Gluon::Component

    def_page_encoding __ENCODING__

    # for Example::Menu and Example::Panel
    def self.description
      'error messages'
    end

    def initialize
      @default = Gluon::Web::ErrorMessages.new
      @default << 'foo'
      @default << 'bar'

      @title = Gluon::Web::ErrorMessages.new(:title => 'NG')
      @title << 'foo'
      @title << 'bar'

      @no_title = Gluon::Web::ErrorMessages.new(:title => false)
      @no_title << 'foo'
      @no_title << 'bar'

      @head_level = Gluon::Web::ErrorMessages.new(:head_level => 3)
      @head_level << 'foo'
      @head_level << 'bar'

      @css_class = Gluon::Web::ErrorMessages.new(:class => 'error')
      @css_class << 'foo'
      @css_class << 'bar'

      @no_messages = Gluon::Web::ErrorMessages.new
    end

    gluon_import_reader :default
    gluon_import_reader :title
    gluon_import_reader :no_title
    gluon_import_reader :head_level
    gluon_import_reader :css_class
    gluon_import_reader :no_messages
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
