# application

require 'gluon/action'
require 'gluon/rs'
require 'rack'

module Gluon
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

    attr_writer :dispatcher
    attr_writer :renderer
    attr_writer :session_man
    attr_writer :plugin_maker
    attr_writer :page_cache

    def call(env)
      req = Rack::Request.new(env)
      res = Rack::Response.new
      page_type, gluon_path_info = @dispatcher.look_up(req.path_info)
      if (page_type) then
        @session_man.transaction(req, res) {|session|
          begin
            req.env['gluon.version'] = VERSION
            req.env['gluon.curr_page'] = page_type
            req.env['gluon.path_info'] = gluon_path_info
            req.env['gluon.page_cache'] = @page_cache
            plugin = @plugin_maker.call
            rs_context = RequestResponseContext.new(req, res, session, @dispatcher, plugin)
            rs_context.cache_tag = nil
            controller = page_type.new
            action = Action.new(controller, rs_context).setup
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
                  result = action.apply(@renderer)
                  if (modified != :no_cache) then
                    # update cache
                    c_entry[:lock].synchronize{
                      c_entry[:cache_tag] = rs_context.cache_tag
                      c_entry[:result] = result
                    }
                  end
                  res.write(result)
                else
                  # use cache
                  res.write(cache_result)
                end
              else
                result = action.apply(@renderer)
                if (@page_cache && rs_context.cache_tag) then
                  # create cache
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


