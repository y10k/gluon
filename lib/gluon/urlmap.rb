# = gluon - simple web application framework
#
# Author:: $Author$
# Date:: $Date$
# Revision:: $Revision$
#
# == license
#   :include:../LICENSE
#

require 'gluon/controller'

module Gluon
  # = URL-class mapping
  class URLMap
    # for ident(1)
    CVS_ID = '$Id$'

    def self.find_path_filter(*args)
      Controller.find_path_filter(*args)
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
      unless (@class2path.key? page_type) then
        @class2path[page_type] = location
      end
      nil
    end

    def setup
      @mapping = @mapping.sort_by{|location, path_filter, page_type|
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

    def each
      for location, path_filter, page_type in @mapping
        yield(location, path_filter, page_type)
      end
      nil
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
