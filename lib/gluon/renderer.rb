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

    def expand_template(page_type)
      case (page_type)
      when Class
        filename = page_type.name
        if (filename.empty?) then
          filename = page_type.to_s
          if (c = page_type.superclass) then
            while (c.name.empty?)
              c = c.superclass
            end
            filename = c.name + '/' + filename
          end
        end
      when String
        filename = page_type
      else
        raise ArgumentError, "unknown page_type for template: #{page_type.class}"
      end
      filename.gsub!(/::/, '/')
      filename.gsub!(%r"[^0-9A-Za-z_/-]+") {|special|
        s = ''
        special.each_byte do |i|
          s << format('%%%02X', i)
        end
        s
      }
      File.join(@template_dir, filename)
    end

    def default_template(controller)
      expand_template(controller.class)
    end

    def compile(view, template)
      compiled_view = view.compile(template)
      template_c = "#{template}c"
      begin
        template_tmp = "#{template_c}.tmp.#{$$}.#{Thread.current.object_id}"
        File.open(template_tmp, 'w') {|out|
          out.write(compiled_view)
        }
        File.rename(template_tmp, template_c)
      rescue SystemCallError
        # nothing to do.
      end
      view.evaluate(compiled_view, template_c)
    end
    private :compile

    def load(view, template)
      stat = File.stat(template)
      cc_entry = @compile_lock.synchronize{
        @compile_cache[template] ||
          @compile_cache[template] = { :lock => Mutex.new }
      }
      cc_entry[:lock].synchronize{
        if (cc_entry.key? :stat) then
          if (cc_entry[:stat].ino == stat.ino &&
              cc_entry[:stat].mtime == stat.mtime &&
              cc_entry[:stat].size == stat.size)
          then
            return cc_entry[:view_class]
          end
        end
        cc_entry[:view_class] = compile(view, template)
        cc_entry[:stat] = stat
        cc_entry[:view_class]
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
