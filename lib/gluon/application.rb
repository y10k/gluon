# = gluon - simple web application framework
#
# Author:: $Author$
# Date:: $Date$
# Revision:: $Revision$
#
# == license
#   :include:../LICENSE
#

require 'gluon/action'
require 'gluon/rs'
require 'rack'

module Gluon
  # = application for Rack
  class Application
    # for ident(1)
    CVS_ID = '$Id$'

    def initialize
      @cache = {}
      @c_lock = Mutex.new

      @default_cache_key = Object.new
      class << @default_cache_key
        def inspect
          super + '(default_cache_key)'
        end
      end
      @default_cache_key.freeze
    end

    attr_writer :logger
    attr_writer :url_map
    attr_writer :renderer
    attr_writer :session_man
    attr_writer :plugin_maker
    attr_writer :page_cache

    def call(env)
      @logger.debug("#{self}.call() - start") if @logger.debug?
      req = Rack::Request.new(env)
      res = Rack::Response.new
      params, funcs = Action.parse(req.params)
      if (@logger.debug?) then
        @logger.debug("request path: #{req.path_info}")
        @logger.debug("request parameters: #{params.inspect}")
        @logger.debug("request functions: #{funcs.inspect}")
      end
      page_type, gluon_path_info, gluon_path_args = @url_map.lookup(req.path_info)
      if (page_type) then
        @session_man.transaction(req, res) {|session|
          begin
            case (page_type)
            when Class
              controller = page_type.new
            when Module
              raise "#{page_type} module is not a page-type."
            else
              controller = page_type
              page_type = controller.class
            end
            req.env['gluon.version'] = VERSION
            req.env['gluon.curr_page'] = page_type
            req.env['gluon.path_info'] = gluon_path_info
            req.env['gluon.path_args'] = gluon_path_args
            req.env['gluon.page_cache'] = @page_cache
            plugin = @plugin_maker.call
            rs_context = RequestResponseContext.new(req, res, session, @url_map, plugin, @renderer)
            rs_context.logger = @logger
            rs_context.cache_tag = nil
            action = Action.new(controller, rs_context, params, funcs).setup
            action.logger = @logger
            page_type = RequestResponseContext.switch_from{
              cache_key = action.cache_key || @default_cache_key
              c_key = [ req.path_info, page_type, cache_key ]
              if (c_entry = @c_lock.synchronize{ @cache[c_key] }) then
                modified = nil
                cache_result = nil
                c_entry[:lock].synchronize{
                  modified = (action.modified? c_entry[:cache_tag])
                  cache_result = c_entry[:result]
                }
                if (modified) then
                  @logger.debug("modified page -> #{c_key.inspect}") if @logger.debug?
                  result = action.apply(gluon_path_args) {
                    action.view_render
                  }
                  if (modified != :no_cache) then
                    @logger.debug("update page cache -> #{c_key.inspect}") if @logger.debug?
                    c_entry[:lock].synchronize{
                      c_entry[:cache_tag] = rs_context.cache_tag
                      c_entry[:result] = result
                    }
                  else
                    @logger.debug("no cache of #{c_key.inspect}") if @logger.debug?
                  end
                  res.write(result)
                else
                  @logger.debug("use page cache -> #{c_key.inspect}") if @logger.debug?
                  res.write(cache_result)
                end
              else
                result = action.apply(gluon_path_args) {
                  action.view_render
                }
                if (@page_cache && rs_context.cache_tag) then
                  @logger.debug("create page cache -> #{c_key.inspect}") if @logger.debug?
                  @c_lock.synchronize{
                    c_entry = @cache[c_key] || { :lock => Mutex.new }
                    c_entry[:lock].synchronize{
                      c_entry[:cache_tag] = rs_context.cache_tag
                      c_entry[:result] = result
                    }
                    @cache[c_key] = c_entry
                  }
                end
                res.write(result)
              end
            }
          end while (page_type)
        }
        @logger.debug("used request parameters: #{params.inspect}")
        @logger.debug("#{self}.call() - end") if @logger.debug?
        return res.finish
      else
        return [ 404, { "Content-Type" => "text/plain" }, [ "404 Not Found: #{req.env['REQUEST_URI']}" ] ]
      end
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
