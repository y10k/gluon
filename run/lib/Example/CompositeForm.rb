# -*- coding: utf-8 -*-

class Example
  class CompositeForm
    extend Gluon::Component

    def_page_encoding __ENCODING__

    # for Example::Menu and Example::Panel
    def self.description
      'composite form'
    end

    class Foo
      extend Gluon::Component

      def initialize(count, value)
        @count = count
        @value = value
      end

      gluon_value_reader :count

      def foo
        @value
      end

      def foo=(value)
        @value = value
      end
      gluon_text :foo, :autoid => true

      alias foo_value foo
      gluon_value :foo_value
    end

    class Bar
      extend Gluon::Component

      def_page_encoding __ENCODING__

      def initialize
        @person = 'Alice'
      end

      gluon_radio_group_accessor :person, %w[ Alice Bob Kate ]

      def alice
        'Alice'
      end
      gluon_radio_button :alice, :person, :autoid => true

      def bob
        'Bob'
      end
      gluon_radio_button :bob, :person, :autoid => true

      def kate
        'Kate'
      end
      gluon_radio_button :kate, :person, :autoid => true
    end

    def initialize
      @foo_list = [ Foo.new(0, "Apple"), Foo.new(1, "Banana"), Foo.new(2, "Orange") ]
      @bar = Bar.new
    end

    gluon_foreach_reader :foo_list
    gluon_import_reader :bar

    def person
      @bar.person
    end
    gluon_value :person

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
