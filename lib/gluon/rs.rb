# request response

require 'thread'
require 'digest'
require 'forwardable'

module Gluon
  class MemoryStore
    # for ident(1)
    CVS_ID = '$Id$'

    def initialize(options={})
      @lock = Mutex.new
      @store = {}
      @expire_interval = options[:expire_interval] || 60 * 5
      @last_expired_time = Time.now
    end

    def create(session)
      @lock.synchronize{
        begin
          id = yield
        end while (@store.key? id)
        @store[id] = {
          :session => session,
          :last_modified => Time.now
        }
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
        if (entry = @store.delete(id)) then
          return entry[:session]
        end
      }
    end

    def expire(alive_time)
      @lock.synchronize{
        now = Time.now
        if (now - @last_expired_time >= @expire_interval) then
          @store.delete_if{|id, entry|
            entry[:last_modified] < alive_time
          }
          @last_expired_time = now
        end
      }
      nil
    end

    def close
      @lock.synchronize{
        @store.clear
        @store.freeze
      }
      nil
    end
  end

  class SessionManager
    # for ident(1)
    CVS_ID = '$Id$'

    def initialize(options={})
      @default_key = options[:default_key] || 'session_id'
      @default_domain = options[:default_domain]
      @default_path = options[:default_path]
      @id_max_length = options[:id_max_length] || 32
      @time_to_live = options[:time_to_live] || 60 * 60
      @auto_expire = (options.key? :auto_expire) ? options[:auto_expire] : true
      @digest = options[:digest] || Digest::MD5
      @store = options[:store] || MemoryStore.new
    end

    attr_reader :default_key
    attr_reader :default_domain
    attr_reader :default_path
    attr_reader :id_max_length
    attr_reader :time_to_live

    def auto_expire?
      @auto_expire
    end

    def new_id
      now = Time.now
      id = @digest.new
      id.update(now.to_s)
      id.update(now.usec.to_s)
      id.update(rand(0).to_s)
      id.update($$.to_s)
      id.update(CVS_ID)
      id.hexdigest[0, @id_max_length]
    end
    private :new_id

    def create(session)
      @store.create(Marshal.dump(session)) { new_id }
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
      @store.expire(now - @time_to_live)
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

    def shutdown
      @store.close
      nil
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

    def get(create=true, options={})
      options = @default_options.dup.update(options)
      key = options.delete(:key) || @man.default_key

      if (@sessions.key? key) then
        id, session, options = @sessions[key]
        return session
      end

      if (@req.cookies.key? key) then
        id, *others = @req.cookies[key]
        unless (session = @man.load(id)) then
          return unless create
          id = @man.create({})
          session = @man.load(id) or raise "internal error: failed to create a new session."
        end
      elsif (create) then
        id = @man.create({})
        session = @man.load(id) or raise "internal error: failed to create a new session."
      else
        return
      end

      @sessions[key] = [ id, session, options ]
      session
    end

    def id(key=@man.default_key)
      if (@sessions.key? key) then
        id, session, options = @sessions[key]
        return id
      end

      if (@req.cookies.key? key) then
        id, *others = @req.cookies[key]
        if (@man.load(id)) then
          return id
        end
      end

      nil
    end

    def delete(key=@man.default_key)
      id, session, options = @sessions.delete(key)
      unless (id) then
        if (@req.cookies.key? key) then
          id, *others = @req.cookies[key]
          session = @man.load(id)
        end
      end
      if (id) then
        @man.delete(id)
      end
      session
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

    def initialize(req, res, session, dispatcher, plugin)
      @req = req
      @res = res
      @session = session
      @dispatcher = dispatcher
      @plugin = plugin
      @cache_tag = nil
    end

    attr_reader :req
    attr_reader :res
    attr_reader :plugin
    attr_accessor :cache_tag

    def_delegator :@session, :get, :session_get
    def_delegator :@session, :id, :session_id
    def_delegator :@session, :delete, :session_delete
    def_delegator :@session, :default_key, :session_default_key
    def_delegator :@session, :default_domain, :session_default_domain
    def_delegator :@session, :default_path, :session_default_path

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
