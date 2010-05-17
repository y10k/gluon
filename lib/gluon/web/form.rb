# -*- coding: utf-8 -*-

require 'gluon/controller'

module Gluon
  module Web
    # form with action path.
    class Form
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

      def initialize(req_res, method='get', attrs={})
        @r = req_res
        @method = method
        @attrs = attrs.map{|n, v| AttrPair.new(n, v) }
      end

      def action
        @r.equest.script_name + @r.equest.path_info
      end
      gluon_value :action

      gluon_value_reader :method
      gluon_foreach_reader :attrs

      module AddOn
        extend Gluon::Component

        def form_params
          []
        end

        def __addon_init__
          super                 # for add-on chain.
          args = form_params
          if (@r.logger.debug?) then
            args_log = args.map{|i| i.inspect }.join(',')
            @r.logger.debug("#{self}: __addon_init__ at #{AddOn}(#{args_log}).")
          end
          @form = Form.new(@r, *args)
        end

        gluon_import_reader :form
      end

      def self.AddOn(*args)
        Module.new{
          include Gluon::Web::Form::AddOn
          define_method(:form_params) { args }
        }
      end
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
