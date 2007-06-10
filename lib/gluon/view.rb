# view renderer

require 'gluon/po'

module Gluon
  class ViewRenderer
    # for idnet(1)
    CVS_ID = '$Id$'

    def initialize(view_dir)
      @view_dir = view_dir
    end

    def render(context)
      view_name = context.po.view_name
      erb_script = IO.read(File.join(@view_dir, view_name))
      Gluon::ERBContext.render(context, erb_script)
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
