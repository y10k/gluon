# -*- coding: utf-8 -*-

class Example
  class Radio
    extend Gluon::Component

    def_page_encoding __ENCODING__

    # for Example::Menu and Example::Panel
    def self.description
      'radio'
    end

    class Person
      extend Gluon::Component

      def initialize(name)
        @person_name = name
        @person_value = name
      end

      def person
        @person_value
      end
      gluon_radio_button :person, :bar, :autoid => true

      gluon_value_reader :person_name
    end

    def initialize
      @foo = 'Apple'
      @bar = 'Bob'
      @person_list = [ Person.new('Alice'), Person.new('Bob'), Person.new('Kate') ]
    end

    gluon_radio_group_accessor :foo, %w[ Apple Banana Orange ]

    def apple
      'Apple'
    end
    gluon_radio_button :apple, :foo, :autoid => true

    def banana
      'Banana'
    end
    gluon_radio_button :banana, :foo, :autoid => true

    def orange
      'Orange'
    end
    gluon_radio_button :orange, :foo, :autoid => true

    alias foo_value foo
    gluon_value :foo_value

    gluon_radio_group_accessor :bar, %w[ Alice Bob Kate ]
    gluon_foreach_reader :person_list

    alias bar_value bar
    gluon_value :bar_value

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
