class Example
  class Table
    class Character
      def initialize(char)
        @char = char
      end

      attr_reader :char

      def code
        format('0x%02X', @char[0])
      end
    end

    class Emphasis
      def initialize(text)
        @text = text
      end

      attr_reader :text
    end

    class Check
      def initialize(text, options={})
        @text = text
        @id = options[:id]
        @checked = false
      end

      attr_reader :text
      attr_reader :id
      attr_accessor :checked
    end

    def page_start
      @auto_table = Gluon::Web::Table.new(:columns => 5,
                                          :items => ('a'..'z').map{|c| Character.new(c) },
                                          :summary => 'auto import table',
                                          :caption => Emphasis.new('automatic (import)'),
                                          :border => false,
                                          :class => 'example',
                                          :id => 'auto-import-table')

      @manual_table = Gluon::Web::Table.new(:columns => 5,
                                            :items => 'a'..'z')

      @auto_form_table = Gluon::Web::Table.new(:columns => 5,
                                               :items => ('a'..'z').map{|c| Check.new(c, :id => "auto-check-#{c}") },
                                               :summary => 'auto form table',
                                               :caption => 'automatic (form)',
                                               :id => 'auto-form-table')

      @manual_form_table = Gluon::Web::Table.new(:columns => 5,
                                                 :items => ('a'..'z').map{|c| Check.new(c) })
    end

    attr_reader :auto_table
    attr_reader :manual_table
    attr_reader :auto_form_table
    attr_reader :manual_form_table
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
