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

      def render(context, eruby_script, filename)
        b = context_binding(context)
        erb = ERB.new(eruby_script)
        erb.filename = filename
        erb.result(b)
      end
    end

    def initialize(view_dir)
      @view_dir = view_dir
    end

    def render(context)
      view_path = context.po.__view__
      erb_script = IO.read(File.join(@view_dir, view_path))
      ViewRenderer.render(context, erb_script, view_path)
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
