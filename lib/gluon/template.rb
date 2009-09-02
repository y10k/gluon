# -*- coding: utf-8 -*-
# = gluon - component based web application framework
# == license
#   :include:../LICENSE
#

require 'gluon/controller'

module Gluon
  class TemplateEngine
    include Memoization

    class Skeleton
      def initialize(po, r)
	@po = po
	@r = r
	@c = @po.controller
	@stdout = ''
      end

      def block_result
        stdout = ''
        stdout_save = @stdout
        begin
          @stdout = stdout
          yield
        ensure
          @stdout = stdout_save
        end

        stdout
      end
      private :block_result
    end

    def initialize(template_dir)
      super()
      @template_dir = template_dir
    end

    def default_template(page_type)
      classpath = page_type.name or raise ArgumentError, "anonymous class has no classpath: #{page_type}"
      classpath.gsub!(/::/, '/')
      File.join(@template_dir, classpath + page_type.page_view.suffix)
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

    def create_engine(view, encoding, template_path, inline_template=nil)
      script = compile(view, encoding, template_path, inline_template)
      engine = Class.new(view.engine_skeleton)
      engine.class_eval("def call\n#{script}\nend", "#{template_path}c", 0)
      engine
    end

    def render(po, r, view, encoding, template_path, inline_template=nil)
      unless (template_path) then
	template_path = default_template(po.controller.class)
      end
      engine = create_engine(view, encoding, template_path, inline_template)
      v = engine.new(po, r)
      v.call
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
