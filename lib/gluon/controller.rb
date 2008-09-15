# = gluon - simple web application framework
#
# Author:: $Author$
# Date:: $Date$
# Revision:: $Revision$
#
# == license
#   :include:../LICENSE
#

module Gluon
  # = controller meta-data
  module Controller
    # for ident(1)
    CVS_ID = '$Id$'

    # :stopdoc:
    PATH_FILTER = {}
    ADVICES = {}
    EXPORT = {}
    # :startdoc:

    # = controller syntax
    module Syntax
      def gluon_path_filter(path_filter)
        PATH_FILTER[self] = path_filter
        nil
      end
      private :gluon_path_filter

      def gluon_advice(name, advices={})
        if (private_method_defined? name) then
          raise NameError, "not advice private method `#{name}'"
        end
        if (protected_method_defined? name) then
          raise NameError, "not advice protected method `#{name}'"
        end
        unless (method_defined? name) then
          raise NameError, "not advice undefined method `#{name}'"
        end

        page_type = self
        ADVICES[page_type] = {} unless (ADVICES.has_key? page_type)

        name = name.to_s if (name.is_a? Symbol)
        ADVICES[page_type][name] = {} unless (ADVICES[page_type].has_key? name)
        ADVICES[page_type][name].update(advices)

        nil
      end
      private :gluon_advice

      def gluon_export(name, advices={})
        if (private_method_defined? name) then
          raise NameError, "not export private method `#{name}'"
        end
        if (protected_method_defined? name) then
          raise NameError, "not export protected method `#{name}'"
        end
        unless (method_defined? name) then
          raise NameError, "not export undefined method `#{name}'"
        end

        gluon_advice name, advices.dup.update(:export => true)

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

    class << self
      def find_path_filter(page_type)
        for page_type in page_type.ancestors
          if (path_filter = PATH_FILTER[page_type]) then
            return path_filter
          end
        end
        nil
      end

      def find_advice(page_type, method_name)
        method_name = method_name.to_s if (method_name.is_a? Symbol)
        advices = {}
        page_type.ancestors.reverse_each do |ancestor|
          if (advices_bundle = ADVICES[ancestor]) then
            if (ancestor_advices = advices_bundle[method_name]) then
              advices.update(ancestor_advices)
            end
          end
        end
        advices
      end

      def find_exported_method(page_type, name)
        advices = find_advice(page_type, name)
        if (advices[:export]) then
          return advices
        end
        nil
      end
    end

    attr_writer :c

    def page_around_hook
      yield
    end

    def page_start
    end

    ## define explicitly
    # def page_get(*path_args)
    # def page_head(*path_args)
    # def page_post(*path_args)

    def page_end
    end

    def __cache_key__
    end

    ## define explicitly
    # def __if_modified__(cache_tag)
    # end
  end
end

class Module
  include Gluon::Controller::Syntax
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
