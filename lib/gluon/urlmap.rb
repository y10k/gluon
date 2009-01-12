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

    def initialize
      @mapping = []
      @class2path = {}
    end

    def mount(page_type, location)
      if (location == '/') then
        location = ''
        path_filter = Controller.find_path_filter(page_type) || %r"^/$"
      else
        path_filter = Controller.find_path_filter(page_type)
      end

      @mapping << [
        location,
        path_filter,
        page_type
      ]

      unless (@class2path.key? page_type) then
        @class2path[page_type] = {
          :location => location,
          :path_filter => path_filter,
          :path_filter_block => Controller.find_path_filter_block(page_type)
        }
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

    def class2path(page_type, *path_args)
      if (mount_point = @class2path[page_type]) then
        path = mount_point[:location]

        if (path_filter = mount_point[:path_filter]) then
          if (block = mount_point[:path_filter_block]) then
            path_info = block.call(*path_args)
          elsif (path_args.length == 1) then
            path_info = path_args[0]
          elsif (path.empty? && path_args.empty?) then
            path_info = '/'
          else
            raise ArgumentError, "invalid path_info for `#{page_type}'"
          end
          if (path_info !~ mount_point[:path_filter]) then
            raise ArgumentError, "`#{path_info}' of path_info is no match to `#{mount_point[:path_filter]}' of path_filter for `#{page_type}'"
          end
          path += path_info
        else
          if (path.empty? && path_args.empty?) then
            path_args = %w[ / ]
          end
          unless (path_args.empty?) then
            raise ArgumentError, "no need for path_info for `#{page_type}'"
          end
        end

        if (path.empty?) then
          path = '/'
        end

        return path
      end

      nil
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
