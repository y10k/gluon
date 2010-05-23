# -*- coding: utf-8 -*-

class Example
  class Checkbox
    extend Gluon::Component

    def_page_encoding __ENCODING__

    # for Example::Menu and Example::Panel
    def self.description
      'checkbox'
    end

    def initialize
      @foo = false
      @bar = false
      @baz = true
    end

    gluon_checkbox_accessor :foo, :autoid => true
    gluon_checkbox_accessor :bar, :autoid => true
    gluon_checkbox_accessor :baz, :autoid => true

    def ok
      # nothing to do.
    end
    gluon_submit :ok

    class Result
      extend Gluon::Component

      def initialize(message)
        @message = message
      end

      gluon_value_reader :message
    end

    def result_list
      results = []
      results << Result.new('foo is checked.') if @foo
      results << Result.new('bar is checked.') if @bar
      results << Result.new('baz is checked.') if @baz
      results
    end
    gluon_foreach :result_list
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
