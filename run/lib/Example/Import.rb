# -*- coding: utf-8 -*-

class Example
  class Import
    extend Gluon::Component

    def self.page_encoding
      __ENCODING__
    end

    # for Example::Menu and Example::Panel
    def self.description
      'import'
    end

    class Foo
      extend Gluon::Component

      def self.page_encoding
        __ENCODING__
      end

      def initialize(message)
        @message = message
      end

      gluon_value_reader :message
    end

    class Bar
      extend Gluon::Component

      def self.page_encoding
        __ENCODING__
      end
    end

    class Baz
      extend Gluon::Component

      def self.page_encoding
        __ENCODING__
      end
    end

    def initialize
      @foo = Foo.new('Hello world.')
      @bar = Bar.new
      @baz1 = Baz.new
      @baz2 = Baz.new
    end

    gluon_import_reader :foo
    gluon_import_reader :bar
    gluon_import_reader :baz1
    gluon_import_reader :baz2
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
