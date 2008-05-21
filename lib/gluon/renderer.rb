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
        view_class = Class.new(ERBContext)
        erb = ERB.new(eruby_script)
        erb.def_method(view_class, '__renderer__', filename)
        view_class
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

    def render(controller, rs_context, action)
      po = PresentationObject.new(controller, rs_context, self, action)
      erb_context = ERBContext.new(po, rs_context)
      view_path = File.join(@view_dir, po.__view__)
      if (po.view_explicit?) then
        view_class = load(view_path)
        return view_class.new(po, rs_context).__renderer__
      elsif (File.exist? view_path) then
        view_class = load(view_path)
        return view_class.new(po, rs_context).__renderer__
      elsif (default_view_path = po.__default_view__) then
        view_class = load(default_view_path)
        return view_class.new(po, rs_context).__renderer__
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
