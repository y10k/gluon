# table

module Gluon
  module Web
    class Table
      # for ident(1)
      CVS_ID = '$Id$'

      class Cell
        def initialize(item)
          @item = item
        end

        attr_reader :item

        def string?
          @item.kind_of? String
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
        def initialize(columns)
          @columns = columns
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

        def cells
          @cells = @row.map{|i| Cell.new(i) } unless @cells
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

        count = 0
        for i in items
          if (count % @columns == 0) then
            row = Row.new(@columns)
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
