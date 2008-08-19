# controller syntax

module Gluon
  module Controller
    # for ident(1)
    CVS_ID = '$Id$'

    # :stopdoc:
    PATH_FILTER = {}
    EXPORT = {}
    # :startdoc:

    module Syntax
      def gluon_path_filter(path_filter)
        PATH_FILTER[self] = path_filter
        nil
      end
      private :gluon_path_filter

      def gluon_export(name, advices={})
        if (private_method_defined? name) then
          raise "not export private method: #{name}"
        end
        if (protected_method_defined? name) then
          raise "not export protected method: #{name}"
        end
        unless (method_defined? name) then
          raise "not export undefined method: #{name}"
        end

        page_type = self
        EXPORT[page_type] = {} unless (EXPORT.has_key? page_type)

        name = name.to_s if (name.is_a? Symbol)
        EXPORT[page_type][name] = advices

        nil
      end
      private :gluon_export

      def gluon_accessor(name, advices={})
        attr_accessor name
        gluon_export name, advices.dup.update(:accessor => true)
        gluon_export "#{name}=", advices.dup.update(:accessor => true)
        nil
      end
      private :gluon_accessor

      def gluon_reader(name, advices={})
        attr_reader name
        gluon_export name, advices.dup.update(:accessor => true)
        nil
      end
      private :gluon_reader

      def gluon_writer(name, advices={})
        attr_writer name
        gluon_export "#{name}=", advices.dup.update(:accessor => true)
        nil
      end
      private :gluon_writer
    end

    def find_path_filter(page_type)
      for page_type in page_type.ancestors
        if (path_filter = PATH_FILTER[page_type]) then
          return path_filter
        end
      end
      nil
    end
    module_function :find_path_filter

    def find_exported_method(page_type, name)
      name = name.to_s if (name.is_a? Symbol)
      for page_type in page_type.ancestors
        if (exported = EXPORT[page_type]) then
          if (advices = exported[name]) then
            return advices
          end
        end
      end
      nil
    end
    module_function :find_exported_method
  end
end

class Module
  include Gluon::Controller::Syntax
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End: