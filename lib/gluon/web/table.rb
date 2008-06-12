# = gluon - simple web application framework
#
# == license
# see <tt>gluon.rb</tt> or <tt>LICENSE</tt> file.
#

module Gluon
  module Web
    # = table rendering utility
    class Table
      # for ident(1)
      CVS_ID = '$Id$'

      class Cell
        def initialize(item, parent, nth, header_columns)
          @item = item
          @parent = parent
          @nth = nth
          @header_columns = header_columns
        end

        attr_reader :item

        def string?
          @item.kind_of? String
        end

        def header_column?
          @nth < @header_columns
        end

        def header?
          header_column? || @parent.header_row?
        end

        def __export__(name)
          case (name)
          when 'item'
            true
          else
            false
          end
        end
      end

      class Row
        def initialize(columns, nth, header_rows, header_columns)
          @columns = columns
          @nth = nth
          @header_rows = header_rows
          @header_columns = header_columns
          @row = []
          @cells = nil
        end

        def <<(item)
          @row << item
          self
        end

        def [](index)
          @row[index]
        end

        def each
          for c in @row
            yield(c)
          end
          nil
        end

        def to_a
          self
        end

        def header_row?
          @nth < @header_rows
        end

        def cells
          unless (@cells) then
            count = 0
            @cells = []
            for i in @row
              @cells << Cell.new(i, self, count, @header_columns)
              count += 1
            end
          end
          @cells
        end

        def last_empty_cells
          (0...(@columns - @row.length)).to_a
        end

        def __export__(name)
          case (name)
          when 'cells'
            true
          else
            false
          end
        end
      end

      def initialize(options={})
        @columns = options[:columns] or raise 'need for columns'
        items = options[:items] or raise 'need for items'
        @rows = []
        @header_rows = options[:header_rows] || 0
        @header_columns = options[:header_columns] || 0

        count = 0
        for i in items
          if (count % @columns == 0) then
            row = Row.new(@columns, count, @header_rows, @header_columns)
            @rows << row
          end
          row << i
          count += 1
        end

        @id = options[:id]
        @summary = options[:summary]
        @width = options[:width]
        @border = (options.key? :border) ? options[:border] : 1
        @frame = options[:frame]
        @rules = options[:rules]
        @css_class = options[:class]
        @caption = options[:caption]
      end

      def [](index)
        @rows[index]
      end

      def each
        for r in @rows
          yield(r)
        end
        nil
      end

      def to_a
        self
      end

      attr_reader :id
      attr_reader :summary
      attr_reader :width
      attr_reader :border
      attr_reader :frame
      attr_reader :rules
      attr_reader :css_class
      attr_reader :caption

      def string_caption?
        @caption.kind_of? String
      end

      def __export__(name)
        case (name)
        when 'caption'
          true
        else
          false
        end
      end

      def __default_view__
        File.join(File.dirname(__FILE__), 'table.rhtml')
      end
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
