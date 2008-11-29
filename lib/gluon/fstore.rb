# = gluon - simple web application framework
#
# Author:: $Author$
# Date:: $Date$
# Revision:: $Revision$
#
# == license
#   :include:../LICENSE
#

require 'fileutils'

module Gluon
  class FileStore
    # for ident(1)
    CVS_ID = '$Id$'

    EXPIRED = '.expired'
    SESSION_EXT = '.ssn'

    def initialize(store_dir, options={})
      @store_dir = store_dir
      @store_expired = File.join(@store_dir, EXPIRED)
      @expire_interval = options[:expire_interval] || 60 * 5
    end

    def make_store
      unless (File.exist? @store_expired) then
        FileUtils.mkdir_p(@store_dir)
        FileUtils.touch(@store_expired)
      end
      nil
    end
    private :make_store

    def session_path(id)
      File.join(@store_dir, id + SESSION_EXT)
    end
    private :session_path

    def creat_and_open(path)
      File.open(path, File::WRONLY | File::CREAT | File::EXCL) {|w|
        yield(w)
      }
    end
    private :creat_and_open

    def create(session)
      make_store

      begin
        id = yield
        ssn_path = session_path(id)
        creat_and_open(ssn_path) {|w|
          w.binmode
          w.write(session)
        }
      rescue Errno::EEXIST
        retry
      end

      id
    end

    def save(id, session)
      make_store
      ssn_path = session_path(id)

      count = 0
      begin
        ssn_path_tmp = "#{ssn_path}.tmp.#{count}"
        creat_and_open(ssn_path_tmp) {|w|
          w.binmode
          w.write(session)
        }
      rescue Errno::EEXIST
        count += 1
        retry
      end
      File.rename(ssn_path_tmp, ssn_path)

      nil
    end

    def load(id)
      make_store
      ssn_path = session_path(id)

      session = nil
      begin
        File.open(ssn_path, 'r') {|r|
          r.binmode
          session = r.read
        }
        FileUtils.touch(ssn_path)
      rescue Errno::ENOENT
        session = nil
      end

      session
    end

    def delete(id)
      make_store
      session = load(id)
      FileUtils.rm_f(session_path(id))
      session
    end

    # :stopdoc:
    SESSION_PATH_PATTERN = Regexp.compile(SESSION_EXT)
    # :startdoc:

    def try_flock_ex(path)
      File.open(path, File::WRONLY) {|f|
        if (f.flock(File::LOCK_EX | File::LOCK_NB)) then
          begin
            yield
          ensure
            f.flock(File::LOCK_UN)
          end
        end
      }
    end
    private :try_flock_ex

    def expire(alive_time)
      make_store

      now = Time.now
      last_expired_time = File.mtime(@store_expired)
      if (now - last_expired_time >= @expire_interval) then
        try_flock_ex(@store_expired) {
          Dir.foreach(@store_dir) do |path|
            case (path)
            when EXPIRED
              next
            when SESSION_PATH_PATTERN
              ssn_path = File.join(@store_dir, path)
              mtime = File.mtime(ssn_path)
              if (mtime < alive_time) then
                FileUtils.rm_f(ssn_path)
              end
            end
          end
          FileUtils.touch(@store_expired)
        }
      end

      nil
    end

    def close
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:
