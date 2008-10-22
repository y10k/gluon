class Example
  class ErrorMessages
    include Gluon::Controller
    include Gluon::ERBView

    CVS_ID = '$Id$'

    def page_start
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

    #def page_get
    def page_import
    end

    attr_reader :default
    attr_reader :title
    attr_reader :no_title
    attr_reader :head_level
    attr_reader :css_class
    attr_reader :no_messages
  end
end
