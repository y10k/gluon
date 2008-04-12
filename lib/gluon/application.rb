# application

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
      begin
	if (page_type) then
	  @session_man.transaction(req, res) {|session|
	    begin
	      req.env['gluon.version'] = VERSION
	      req.env['gluon.curr_page'] = page_type
	      req.env['gluon.path_info'] = gluon_path_info
	      req.env['gluon.page_cache'] = @page_cache
	      plugin = @plugin_maker.new_plugin
	      rs_context = RequestResponseContext.new(req, res, session, @dispatcher, plugin)
	      begin
		rs_context.cache_tag = nil
		page = page_type.new
		action = Action.new(page, rs_context).setup
		po = PresentationObject.new(page, rs_context, @renderer)
		erb_context = ERBContext.new(po, rs_context)
		page_type = RequestResponseContext.switch_from{
		  begin
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
			result = action.apply{ @renderer.render(erb_context) }
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
		      result = action.apply{
			@renderer.render(erb_context)
		      }
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
		  ensure	# repair for leak
		    cache_key = nil
		    c_key = nil
		    c_entry = nil
		    modified = nil
		    cache_result = nil
		    result = nil
		  end
		}
	      end while (page_type)
	    ensure		# repair for leak
	      session = nil
	      plugin = nil
	      rs_context = nil
	      page = nil
	      action = nil
	      po = nil
	      erb_context = nil
	      page_type = nil
	    end
	  }
	  return res.finish
	else
	  return [ 404, { "Content-Type" => "text/plain" }, [ "404 Not Found: #{req.env['REQUEST_URI']}" ] ]
	end
      ensure			# repair for leak
	req = nil
	res = nil
	page_type = nil
	gluon_path_info = nil
      end
    end
  end
end


