# = gluon - simple web application framework
#
# Author:: $Author$
# Date:: $Date$
# Revision:: $Revision$
#
# == license
#   :include:../LICENSE
#

require 'erb'
require 'gluon/po'
require 'thread'

module Gluon
  class ViewRenderer
    # for idnet(1)
    CVS_ID = '$Id$'

    def initialize(template_dir)
      @template_dir = template_dir
      @compile_lock = Mutex.new
      @compile_cache = {}
    end

    def default_template(controller)
      File.join(@template_dir,
                controller.class.name.gsub(/::/, File::SEPARATOR))
    end

    def compile(view, template)
      compiled_view = view.compile(template)
      template_c = "#{template}c"
      File.open(template_c, 'w') {|out|
        out.write(compiled_view)
      }
      view.evaluate(compiled_view, template_c)
    end
    private :compile

    def load(view, template)
      stat = File.stat(template)
      @compile_lock.synchronize{
        if (entry = @compile_cache[template]) then
          if (entry[:stat].ino == stat.ino &&
              entry[:stat].mtime == stat.mtime &&
              entry[:stat].size == stat.size)
          then
            return entry[:view_class]
          end
        end

        @compile_cache[template] = {
          :stat => stat,
          :view_class => compile(view, template)
        }
        @compile_cache[template][:view_class]
      }
    end

    def render(view, template, rs_context, po)
      view_type = load(view, template)
      view_handler = view_type.new(po, rs_context)
      view_handler.call
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
