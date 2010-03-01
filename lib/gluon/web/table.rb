# -*- coding: utf-8 -*-

require 'gluon/controller'

module Gluon
  module Web
    class StringTableItem
      extend Gluon::Component

      def_page_encoding __ENCODING__

      def_page_template File.join(File.dirname(__FILE__),
                                  File.basename(__FILE__, '.rb') + '_item.erb')

      def initialize(value)
        @value = value
      end

      gluon_value_reader :value
    end

    class ImportTable
      extend Gluon::Component

      def_page_encoding __ENCODING__

      def_page_template File.join(File.dirname(__FILE__),
                                  File.basename(__FILE__, '.rb') + '.erb')

      class AttrPair
        extend Gluon::Component

        def initialize(name, value)
          @name = name
          @value = value
        end

        gluon_value_reader :name
        gluon_value_reader :value
      end

      class Cell
        extend Gluon::Component

        def initialize(type, item, attrs={})
          @type = type
          @item = item
          @attrs = attrs.map{|n, v| AttrPair.new(n, v) }
        end

        def header?
          @type == :header
        end
        gluon_cond :header?

        def data?
          @type == :data
        end
        gluon_cond :data?

        gluon_import_reader :item
        gluon_foreach_reader :attrs
      end

      class Header < Cell
        def initialize(*args)
          super(:header, *args)
        end
      end

      class Data < Cell
        def initialize(*args)
          super(:data, *args)
        end
      end

      class Row
        extend Gluon::Component

        def initialize(cells, attrs={})
          @cells = cells
          @attrs = attrs.map{|n, v| AttrPair.new(n, v) }
        end

        gluon_foreach_reader :cells
        gluon_foreach_reader :attrs
      end

      class DslRow
        def initialize(cells)
          @cells = cells
        end

        def th(item, attrs={})
          item = StringTableItem.new(item) if (item.is_a? String)
          @cells << Header.new(item, attrs)
          self
        end

        def td(item, attrs={})
          item = StringTableItem.new(item) if (item.is_a? String)
          @cells << Data.new(item, attrs)
          self
        end
      end

      def initialize(attrs={})
        @attrs = attrs.map{|n, v| AttrPair.new(n, v) }
        @caption = nil
        @rows = []
      end

      attr_accessor :caption

      def tr(attrs={})
        cells = []
        @rows << Row.new(cells, attrs)
        row = DslRow.new(cells)
        if (block_given?) then
          yield(row)
        end

        row
      end

      gluon_foreach_reader :attrs
      gluon_value :caption
      alias exist_caption? caption
      gluon_cond :exist_caption?
      gluon_foreach_reader :rows
    end

    class ForeachTable
      extend Gluon::Component
      include Enumerable

      class Row
        extend Gluon::Component

        def initialize(cells)
          @cells = cells
        end

        gluon_foreach_reader :cells
      end

      class DslRow
        def initialize(cells)
          @cells = cells
        end

        def th(item, attrs={})
          @cells << item
          self
        end

        def td(item, attrs={})
          @cells << item
          self
        end
      end

      def initialize(attrs={})
        @rows = []
      end

      def tr(attrs={})
        cells = []
        @rows << Row.new(cells)
        row = DslRow.new(cells)
        if (block_given?) then
          yield(row)
        end
        row
      end

      def [](*args)
        @rows[*args]
      end

      def each(&block)
        @rows.each(&block)
      end
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
