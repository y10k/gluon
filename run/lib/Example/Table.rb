class Example
  class Table
    include Gluon::Controller
    include Gluon::ERBView

    class Character
      include Gluon::Controller
      include Gluon::ERBView

      def initialize(char)
        @char = char
      end

      def page_import
      end

      attr_reader :char

      def code
        format('0x%02X', @char[0])
      end
    end

    class Emphasis
      include Gluon::Controller
      include Gluon::ERBView

      def initialize(text)
        @text = text
      end

      def page_import
      end

      attr_reader :text
    end

    class Check
      include Gluon::Controller
      include Gluon::ERBView

      def initialize(text, options={})
        @text = text
        @check_id = options[:id]
        @checked = false
      end

      def page_import
      end

      attr_reader :text
      attr_reader :check_id
      gluon_export_accessor :checked
    end

    def page_start
      @auto_table = Gluon::Web::Table.new(:columns => 5,
                                          :items => ('a'..'z').map{|c| Character.new(c) },
                                          :header_rows => 1,
                                          :header_columns => 1,
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

    #def page_start
    #def page_post
    def page_import
    end

    def action_path
      @c.class2path(ExamplePanel, Table)
    end

    attr_reader :auto_table
    attr_reader :manual_table
    gluon_export_reader :auto_form_table
    gluon_export_reader :manual_form_table
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
