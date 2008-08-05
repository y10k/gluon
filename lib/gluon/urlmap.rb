# URL-class mapping

module Gluon
  class URLMap
    # for ident(1)
    CVS_ID = '$Id$'

    # :stopdoc:
    DEFAULT_PATH_FILTER = {}
    # :startdoc:

    def self.find_path_filter(page_type)
      begin
        if (path_filter = DEFAULT_PATH_FILTER[page_type]) then
          return path_filter
        end
      end while (page_type = page_type.superclass)

      nil
    end

    def initialize
      @mapping = []
      @class2path = {}
    end

    def mount(page_type, location, path_filter=nil)
      if (location == '/') then
        @mapping << [
          '',
          path_filter || URLMap.find_path_filter(page_type) || '/',
          page_type
        ]
      else
        @mapping << [
          location,
          path_filter || URLMap.find_path_filter(page_type),
          page_type
        ]
      end
      @class2path[page_type] = location
      nil
    end

    def setup
      @mapping.sort_by{|location, path_filter, page_type|
        -(location.length)
      }
      self
    end

    def lookup(path)
      for location, path_filter, page_type in @mapping
        if (path_filter) then
          script_name = path[0...location.length]
          path_info = path[location.length..-1]
          if (location == script_name) then
            if (path_filter === path_info) then
              if ($~) then
                args = $~.to_a
                args.shift
                return page_type, path_info, args
              else
                return page_type, path_info, []
              end
            end
          end
        else
          if (location == path) then
            return page_type, nil, []
          end
        end
      end

      nil
    end

    def class2path(page_type)
      @class2path[page_type]
    end
  end
end

class Class
  def gluon_path_filter(path_filter)
    Gluon::URLMap::DEFAULT_PATH_FILTER[self] = path_filter
    nil
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
