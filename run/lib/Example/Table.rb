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
      @import_table = Gluon::Web::ImportTable.new(:summary => 'import table', :border => 1)
      @import_table.caption = 'import table'
      t = @import_table         # alias
      t.tr.th('X').th('A').th('B').th('C').th('D').th('E')
      t.tr{|r| r.th('1'); ('a'..'e').each{|c| r.td(Character.new(c)) } }
      t.tr{|r| r.th('2'); ('f'..'j').each{|c| r.td(Character.new(c)) } }
      t.tr{|r| r.th('3'); ('k'..'o').each{|c| r.td(Character.new(c)) } }
      t.tr{|r| r.th('4'); ('p'..'t').each{|c| r.td(Character.new(c)) } }
      t.tr{|r| r.th('5'); ('u'..'y').each{|c| r.td(Character.new(c)) } }
      t.tr{|r| r.th('6'); r.td(Character.new('z')); 4.times{ r.td('-', :align => 'center') } }

      @foreach_table = Gluon::Web::ForeachTable.new
      u = @foreach_table        # alias
      [ %w[ 17 24  1  8 15 ],
        %w[ 23  5  7 14 16 ],
        %w[  4  6 13 20 22 ],
        %w[ 10 12 19 21  3 ],
        %w[ 11 18 25  2  9 ]
      ].each do |numbers|
        u.tr{|r|
          for n in numbers
            r.td(Number.new(n))
          end
        }
      end

      @form_table = Gluon::Web::ForeachTable.new
      @check_list = []
      v = @form_table
      [ 'a'..'e',
        'f'..'j',
        'k'..'o',
        'p'..'t',
        'u'..'y',
        'z'..'dd'
      ].each do |chars|
        v.tr{|r|
          for c in chars
            check = Check.new("check-#{c}", c)
            r.td(check)
            @check_list << check
          end
        }
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
