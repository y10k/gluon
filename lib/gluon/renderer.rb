# view renderer

require 'erb'

module Gluon
  class ViewRenderer
    # for idnet(1)
    CVS_ID = '$Id$'

    class << self
      def context_binding(_)
        _.instance_eval{ binding }
      end

      def render(erb_context, eruby_script, filename)
        b = context_binding(erb_context)
        erb = ERB.new(eruby_script)
        erb.filename = filename
        erb.result(b)
      end
    end

    def initialize(view_dir)
      @view_dir = view_dir
    end

    def render(erb_context)
      view_path = File.join(@view_dir, erb_context.po.__view__)
      if (File.exist? view_path) then
        erb_script = IO.read(view_path)
        return ViewRenderer.render(erb_context, erb_script, view_path)
      elsif (default_view_path = erb_context.po.__default_view__) then
        erb_script = IO.read(default_view_path)
        return ViewRenderer.render(erb_context, erb_script, default_view_path)
      end

      raise 'no view'
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
