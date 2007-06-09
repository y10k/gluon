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
    end

    def look_up(path)
      @mapping.each{|location, page_type|
	if (location == path[0, location.size] &&
	    (path[location.size] == nil || path[location.size] == ?/))
	then
	  return page_type
	end
      }
      nil
    end
  end
end
