# -*- coding: utf-8 -*-

require 'gluon/controller'

module Gluon
  # = class-URL mapping
  class ClassMap
    def initialize
      @cmap = {}
    end

    def mount(page_type, location)
      if (location !~ %r"^/") then
        raise ArgumentError, "need to start with slash: #{location}"
      end
      @cmap[page_type] = location
      nil
    end

    def class2path(page_type, *path_args)
      location = @cmap[page_type] or raise ArgumentError, "not mounted class: #{page_type}"

      if (block = Controller.find_path_match_block(page_type)) then
        path_info = block.call(*path_args)
      else
        unless (path_args.empty?) then
          raise ArgumentError, 'no need for path arguments.'
        end
        path_info = ''
      end

      unless (path_info.empty?) then
        if (path_info !~ %r"^/") then
          raise "PATH_INFO of `#{page_type}' needs to start with slash: #{path_info}"
        end
        if (location == '/') then
          location = path_info
        else
          location += path_info
        end
      end

      location
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
