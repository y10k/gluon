# view renderer

require 'erb'
require 'thread'

module Gluon
  class ViewRenderer
    # for idnet(1)
    CVS_ID = '$Id$'

    class << self
      def compile_view(script, filename='(erb)')
        erb = ERB.new(script)
        eval('proc{ ' + erb.src + '}', TOPLEVEL_BINDING, filename)
      end

      def load_view(filename)
        script = IO.read(filename)
        compile_view(script, filename)
      end
    end

    def initialize(view_dir)
      @view_dir = view_dir
      @compile_lock = Mutex.new
      @compile_cache = {}
    end

    def load_view(filename)
      mtime = File.stat(filename).mtime
      @compile_lock.synchronize{
        if (entry = @compile_cache[filename]) then
          if (entry[:mtime] == mtime) then
            return entry[:proc]
          end
        end

        @compile_cache[filename] = {
          :mtime => mtime,
          :proc => ViewRenderer.load_view(filename)
        }
        @compile_cache[filename][:proc]
      }
    end
    private :load_view

    def render(erb_context)
      po = erb_context.po
      view_path = File.join(@view_dir, po.__view__)
      if (po.view_explicit?) then
        erb_proc = load_view(view_path)
        return erb_context.instance_eval(&erb_proc)
      elsif (File.exist? view_path) then
        erb_proc = load_view(view_path)
        return erb_context.instance_eval(&erb_proc)
      elsif (default_view_path = po.__default_view__) then
        erb_proc = load_view(default_view_path)
        return erb_context.instance_eval(&erb_proc)
      end

      raise "no view for #{po.page_type}"
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
