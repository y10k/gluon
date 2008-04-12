# view renderer

require 'erb'
require 'gluon/po'
require 'thread'

module Gluon
  class ViewRenderer
    # for idnet(1)
    CVS_ID = '$Id$'

    class << self
      def compile(eruby_script, filename='(erb)')
        erb = ERB.new(eruby_script)
        eval('proc{ ' + erb.src + '}', TOPLEVEL_BINDING, filename)
      end

      def load(filename)
        script = IO.read(filename)
        compile(script, filename)
      end
    end

    def initialize(view_dir)
      @view_dir = view_dir
      @compile_lock = Mutex.new
      @compile_cache = {}
    end

    def load(filename)
      mtime = File.stat(filename).mtime
      @compile_lock.synchronize{
        if (entry = @compile_cache[filename]) then
          if (entry[:mtime] == mtime) then
            return entry[:proc]
          end
        end

        @compile_cache[filename] = {
          :mtime => mtime,
          :proc => ViewRenderer.load(filename)
        }
        @compile_cache[filename][:proc]
      }
    end
    private :load

    def render(page, rs_context)
      po = PresentationObject.new(page, rs_context, self)
      erb_context = ERBContext.new(po, rs_context)
      view_path = File.join(@view_dir, po.__view__)
      if (po.view_explicit?) then
        erb_proc = load(view_path)
        return erb_context.instance_eval(&erb_proc)
      elsif (File.exist? view_path) then
        erb_proc = load(view_path)
        return erb_context.instance_eval(&erb_proc)
      elsif (default_view_path = po.__default_view__) then
        erb_proc = load(default_view_path)
        return erb_context.instance_eval(&erb_proc)
      end

      raise "no view for #{po.page_type}"
    end

    alias call render
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
