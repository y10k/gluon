# -*- coding: utf-8 -*-

require 'Example/Panel'

class Example
  class ViewPanel < Panel
    def self.page_encoding
      __ENCODING__
    end

    VIEW_DIR = File.join(File.dirname(__FILE__), '..', '..', 'view')

    class ViewCode
      extend Gluon::Component

      def initialize(example_type, view_path)
        @example_type = example_type
        @view_path = view_path
      end

      def example_type
        @example_type.name
      end
      gluon_value :example_type

      def filename
        File.basename(@view_path)
      end
      gluon_value :filename

      def view_code
        File.open(@view_path, "r:#{@example_type.page_encoding}") {|f| f.read }
      end
      gluon_value :view_code
    end

    def search_child_components(c)
      export = Gluon::Controller.find_view_export(c.class)
      for name, entry in export
        if (entry[:type] == :import) then
          if (child = c.__send__(name)) then
            @component_type[child.class] = true
            search_child_components(child)
          end
        end
      end

      nil
    end
    private :search_child_components

    def page_start
      super
      @component_type = { @example_type => true }
      search_child_components(@example_type.new)

      @view_code_list = []
      @component_type.each_key do |example_type|
        if (view_code_path = example_type.page_template) then
          @view_code_list.push ViewCode.new(example_type, view_code_path)
        else
          @view_code_list.push ViewCode.new(example_type,
                                            File.join(VIEW_DIR,
                                                      example_type.name.gsub(/::/, '/') +
                                                      example_type.page_view.suffix))
        end
      end
    end

    gluon_foreach_reader :view_code_list
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
