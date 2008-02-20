# request response

require 'thread'
require 'digest'
require 'forwardable'

module Gluon
  class MemoryStore
    # for ident(1)
    CVS_ID = '$Id$'

    def initialize
      @lock = Mutex.new
      @store = {}
    end

    def new_id
      @lock.synchronize{
        begin
          id = yield
        end while (@store.key? id)
        id
      }
    end

    def save(id, session)
      @lock.synchronize{
        @store[id] = {
          :session => session,
          :last_modified => Time.now
        }
      }
      nil
    end

    def load(id)
      @lock.synchronize{
        if (entry = @store[id]) then
          entry[:last_modified] = Time.now
          return entry[:session]
        end
      }
      nil
    end

    def delete(id)
      @lock.synchronize{
        @store.delete(id)
      }
    end

    def expire(alive_time)
      @lock.synchronize{
        @store.delete_if{|id, entry|
          entry[:last_modified] < alive_time
        }
      }
      nil
    end
  end

  class SessionNotFoundError < StandardError
  end

  class SessionManager
    # for ident(1)
    CVS_ID = '$Id$'

    def initialize(options={})
      @default_key = options[:default_key] || 'session_id'
      @default_domain = options[:default_domain]
      @default_path = options[:default_path]
      @id_max_length = options[:id_max_length] || 32
      @life_time = options[:life_time] || 60 * 60
      @auto_expire = (options.key? :auto_expire) ? options[:auto_expire] : true
      @digest = options[:digest] || Digest::MD5
      @store = options[:store] || MemoryStore.new
    end

    attr_reader :default_key
    attr_reader :default_domain
    attr_reader :default_path
    attr_reader :id_max_length
    attr_reader :life_time

    def auto_expire?
      @auto_expire
    end

    def create_new_id
      now = Time.now
      id = @digest.new
      id.update(now.to_s)
      id.update(now.usec.to_s)
      id.update(rand(0).to_s)
      id.update($$.to_s)
      id.update(CVS_ID)
      id.hexdigest[0, @id_max_length]
    end
    private :create_new_id

    def new_id
      @store.new_id{ create_new_id }
    end

    def save(id, session)
      @store.save(id, Marshal.dump(session))
      nil
    end

    def load(id)
      if (session = @store.load(id)) then
        return Marshal.load(session)
      end
      nil
    end

    def delete(id)
      @store.delete(id)
      nil
    end

    def expire(now=Time.now)
      @store.expire(now - @life_time)
      nil
    end

    def transaction(req, res)
      handler = SessionHandler.new(self, req, res)
      begin
        r = yield(handler)
        handler.save_all
      ensure
        expire if @auto_expire
      end
      r
    end
  end

  class SessionHandler
    # for ident(1)
    CVS_ID = '$Id$'

    extend Forwardable

    def initialize(man, req, res)
      @man = man
      @req = req
      @res = res
      @sessions = {}
      @default_options = {}
      @default_options[:domain] = @man.default_domain if @man.default_domain
      @default_options[:path] = @man.default_path if @man.default_path
      @default_options.freeze
    end

    def_delegator :@man, :default_key

    def new_session(create=true, options={})
      options = @default_options.dup.update(options)
      key = options.delete(:key) || @man.default_key
      if (id = @req.cookies[key]) then
        # nothing to do.
      elsif (@sessions.key? key) then
        id = @sessions[key][0]
      else
        unless (create) then
          raise SessionNotFoundError, "not found a session: #{key}"
        end
        id = @man.new_id
      end
      session = @man.load(id) || {}
      @sessions[key] = [ id, session, options ]
      session
    end

    def delete(key=@man.default_key)
      id, session = @sessions.delete(key)
      @man.delete(id) if id
      nil
    end

    def save_all
      for key, (id, session, options) in @sessions
        @man.save(id, session)
        if (options.empty?) then
          @res.set_cookie(key, id)
        else
          options[:value] = id
          @res.set_cookie(key, options)
        end
      end
      nil
    end
  end

  class RequestResponseContext
    # for idnet(1)
    CVS_ID = '$Id$'

    extend Forwardable

    def initialize(req, res, session, dispatcher)
      @req = req
      @res = res
      @session = session
      @dispatcher = dispatcher
    end

    attr_reader :req
    attr_reader :res

    def_delegator :@session, :new_session
    def_delegator :@session, :delete, :delete_session
    def_delegator :@session, :default_key, :default_session_key
    def_delegator :@session, :default_domain, :default_session_domain
    def_delegator :@session, :default_path, :default_session_path

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

    SWITCH_LABEL = :gluon_switch

    def switch_to(page)
      throw(SWITCH_LABEL, page)
    end

    def self.switch_from
      catch(SWITCH_LABEL) {
        yield
        nil
      }
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
