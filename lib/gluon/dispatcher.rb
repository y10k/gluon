# URL dispatcher

module Gluon
  class Dispatcher
    # for ident(1)
    CVS_ID = '$Id$'

    def initialize(url_map)
      @mapping = url_map.map{|location, page_type|
        location = '' if (location == '/')
        [ location, page_type ]
      }.sort_by{|location, page_type| -(location.size) }
      @class2path = {}
      for location, page_type in @mapping
        @class2path[page_type] = location
      end
    end

    def look_up(path)
      @mapping.each{|location, page_type|
        if (location == path[0, location.size] &&
            (path[location.size] == nil || path[location.size] == ?/))
        then
          return page_type, path[location.size..-1]
        end
      }
      nil
    end

    def class2path(page_type)
      @class2path[page_type]
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
