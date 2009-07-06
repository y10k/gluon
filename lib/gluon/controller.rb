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
  # = controller and meta-data
  # these methods may be explicitly defined at included class.
  #
  module Controller
    # for ident(1)
    CVS_ID = '$Id$'

    # :stopdoc:
    PATH_FILTER = {}
    # :startdoc:

    # = controller syntax
    module Syntax
      private

      def gluon_path_filter(path_filter, &block)
        PATH_FILTER[self] = {
          :filter => path_filter,
          :block => block
        }
        nil
      end

      def gluon_value(name, options={})
      end

      def gluon_cond(name, options={})
      end

      def gluon_foreach(name, options={})
      end

      def gluon_link(name, options={})
      end

      def gluon_action(name, options={})
      end

      def gluon_frame(name, options={})
      end

      def gluon_import(name, options={}, &block)
      end

      def gluon_text(name, options={})
      end

      def gluon_passwd(name, options={})
      end

      def gluon_submit(name, options={})
      end

      def gluon_hidden(name, options={})
      end

      def gluon_checkbox(name, options={})
      end

      def gluon_radio(name, list, options={})
      end

      def gluon_select(name, list, options={})
      end

      def gluon_textarea(name, options={})
      end
    end

    def append_features(module_or_class)
      module_or_class.extend(Controller)
      super
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
