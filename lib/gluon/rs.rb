# request response

require 'forwardable'

module Gluon
  class RequestResponseContext
    # for idnet(1)
    CVS_ID = '$Id$'

    extend Forwardable

    def initialize(req, res, dispatcher)
      @req = req
      @res = res
      @dispatcher = dispatcher
    end

    attr_reader :req
    attr_reader :res
    def_delegator :@dispatcher, :look_up
    def_delegator :@dispatcher, :class2path

    def version
      @req.env['gluon.version']
    end

    def curr_page
      @req.env['gluon.curr_page']
    end

    def path_info
      @req.env['gluon.path_info']
    end

    def location(path)
      path = '/' if path.empty?
      @res['Location'] = path
      @res.status = 302
      self
    end

    def redirect_to(page)
      location(@req.script_name + @dispatcher.class2path(page))
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
