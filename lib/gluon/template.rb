# -*- coding: utf-8 -*-
# = gluon - simple web application framework
# == license
#   :include:../LICENSE
#

module Gluon
  class TemplateEngine
    # for ident(1)
    CVS_ID = '$Id$'

    class Skeleton
      def initialize(po, rs)
	@po = po
	@r = rs
	@c = @po.controller
	@stdout = ''
      end
    end

    def default_template(page_type)
      raise NotImplementedError, 'not implemented.'
    end

    def compile(view, encoding, template_path, inline_template=nil)
      if (inline_template) then
	template = inline_template
      else
	template = File.open(template_path, "r:#{encoding}") {|f| f.read }
      end
      script = view.compile(template)

      compile_path = "#{template_path}c"
      begin
	compile_tmp = "#{compile_path}.tmp.#{$$}.#{Thread.current.object_id}"
	File.open(compile_tmp, "w:#{encoding}") {|f|
	  f.write(script)
	}
	File.rename(compile_tmp, compile_path)
      rescue SystemCallError
	# skip error.
      end

      script
    end

    def create_engine(view, template_path, script)
      engine = Class.new(view.engine_skeleton)
      engine.class_eval("def call\n#{script}\nend", "#{template_path}c", 0)
      engine
    end

    def render(po, rs, view, encoding, template_path, inline_template=nil)
      unless (template_path) then
	template_path = default_template(po.class)
      end
      script = compile(view, encoding, template_path, inline_template)
      engine = create_engine(view, template_path, script)
      v = engine.new(po, rs)
      v.call
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
