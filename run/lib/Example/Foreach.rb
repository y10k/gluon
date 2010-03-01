# -*- coding: utf-8 -*-

class Example
  class Foreach
    extend Gluon::Component

    def_page_encoding __ENCODING__

    # for Example::Menu and Example::Panel
    def self.description
      'foreach'
    end

    class Person
      extend Gluon::Component

      def initialize(name, age)
        @name = name
        @age = age
      end

      gluon_value_reader :name
      gluon_value_reader :age
    end

    def initialize
      @persons = [
        Person.new('Taro', 21),
        Person.new('Hanako', 23),
        Person.new('Tanaka', 18)
      ]
      @country = 'Japanese'
    end

    gluon_foreach_reader :persons
    gluon_value_reader :country
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
