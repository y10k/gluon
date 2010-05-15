# -*- coding: utf-8 -*-

class Example
  class Table
    extend Gluon::Component

    def_page_encoding __ENCODING__

    # for Example::Menu and Example::Panel
    def self.description
      'table utility'
    end

    class Character
      extend Gluon::Component

      def_page_encoding __ENCODING__

      def initialize(char)
        @char = char
      end

      gluon_value_reader :char

      def code
        format('0x%02X', @char.ord)
      end
      gluon_value :code
    end

    class Number
      extend Gluon::Component

      def initialize(number)
        @number = number
      end

      gluon_value_reader :number
    end

    class Check
      extend Gluon::Component

      def initialize(id, text)
        @text = text
        @check_id = id
        @checked = false
      end

      gluon_value_reader :text
      gluon_value_reader :check_id
      gluon_checkbox_accessor :checked, :attrs => { 'id' => :check_id }
    end

    def initialize
      import_data = %w[
        X A B C D E
        1 a b c d e
        2 f g h i j
        3 k l m n o
        4 p q r s t
        5 u v w x y
        6 z
      ]
      @import_table = Gluon::Web::ImportTable.build(6, import_data,
                                                    'summary' => 'import table',
                                                    'border' => 1) do |tbl, rows|
        tbl.caption = 'import table'
        tbl.tr{|tr|
          for v in rows.next
            tr.th(v)
          end
        }
        loop do
          head, *data = rows.next
          tbl.tr{|tr|
            tr.th(head)
            for c in data
              tr.td(Character.new(c))
            end
            (5 - data.length).times do
              tr.td('-', 'align' => 'center')
            end
          }
        end
      end

      foreach_data = %w[
        17 24  1  8 15
        23  5  7 14 16
         4  6 13 20 22
        10 12 19 21  3
        11 18 25  2  9
      ]
      @foreach_table = Gluon::Web::ForeachTable.build(5, foreach_data.map{|n| Number.new(n) })

      form_data = %w[
        a b c d e
        f g h i j
        k l m n o
        p q r s t
        u v w x y
        z aa bb cc dd
      ]
      @check_list = []
      @form_table = Gluon::Web::ForeachTable.build(5, form_data) do |tbl, rows|
        loop do
          tbl.tr{|tr|
            for c in rows.next
              check = Check.new("check-#{c}", c)
              tr.td(check)
              @check_list << check
            end
          }
        end
      end
    end

    gluon_import_reader :import_table
    gluon_foreach_reader :foreach_table
    gluon_foreach_reader :form_table

    def checked_values
      @check_list.find_all{|c| c.checked }.map{|c| c.text }.join(', ')
    end
    gluon_value :checked_values

    def ok
    end
    gluon_submit :ok
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
