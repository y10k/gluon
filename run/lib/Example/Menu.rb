# -*- coding: utf-8 -*-

class Example
  class Menu < Gluon::Controller
    def_page_encoding __ENCODING__

    class Item
      extend Gluon::Component

      def self.key(example_type)
        example_type.name.sub(/^Example::/, '')
      end

      def initialize(example_type)
        @example_type = example_type
      end

      attr_reader :example_type

      def example
        return ExamplePanel, @example_type
      end
      gluon_link :example, :attrs => { 'target' => 'main' }

      def description
        @example_type.description
      end
      gluon_value :description
    end

    Items = {}
    for example in [ Value, Cond, Foreach, Link, Action, Import,
        Submit, Text, Passwd, Checkbox, Radio, Select, Textarea,
        CompositeForm, ErrorMessages, OneTimeToken, Table, BackendService ]
      Items[Item.key(example)] = Item.new(example)
    end

    def examples
      Items.values
    end
    gluon_foreach :examples

    def welcom
      return Welcom
    end
    gluon_link :welcom, :attrs => { 'target' => '_top' }
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
