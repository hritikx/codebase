
require 'uri'

module URI
  class GIT < Generic
    DEFAULT_PORT = 9418
  end
  @@schemes['GIT'] = GIT
end

module GitMirror
  class URL
    attr_reader :schema, :user, :password, :host, :port, :path

    private def initialize(url)
      url = url.to_s
      raise 'Empty url' if url.empty?

      begin
        url = URI.parse(url)

        @schema = url.scheme
        @user = url.user
        @password = url.password
        @host = url.host
        @port = url.port
        @path = url.path

        return
      rescue
      end

      host, path = url.to_s.split(':', 2)
      if host.length == 1 && path[0] == '\\'
        #local windows path
        @path = url
        return
      end

      if host.length > 0 && path.length > 0
        return if parse_scp_like_url(host, path)
      end

      raise 'Unknown git remote url'
    end

    private def parse_scp_like_url(host, path)
      return if !path || path.include?(':') || path[0] == '/'

      if host.include? ('@')
        user, host = host.split('@', 2)

        return if user.length <= 0
        return if host.include?('@')

        @user = user
        @host = host
      else
        @host = host
      end

      @path = '/' + path
    end

    def remote?
      !self.local?
    end

    def local?
      (@schema.nil? && !scp_like?) || @schema == "file"
    end

    def scp_like?
      @schema.nil? && !@host.nil?
    end

    def uses_ssh?
      @schema == 'ssh' || self.scp_like?
    end

    def normalize
      o = self.dup
      o.instance_variable_set(:@user, '***') if @user
      o.instance_variable_set(:@password, '***') if @password

      return o.to_s
    end

    def to_h
      rez = {}
      rez[:schema] = @schema if @schema
      rez[:user] = @user if @user
      rez[:password] = @password if @password
      rez[:host] = @host if @host
      rez[:port] = @port if @port
      rez[:path] = @path if @path
      rez
    end

    def to_s
      s = StringIO.new

      if @schema
        s << @schema
        s << '://'

        if @user
          s << @user
          if @password
            s << ':'
            s << @password
          end
          s << '@'
        end

        s << @host
        s << path
      elsif @host
        if @user
          s << @user
          s << '@'
        end

        s << host
        s << ':'
        s << path[1..-1]
      else
        return path
      end

      s.string
    end

    class << self
      def parse(url)
        return url if url.is_a? self

        self.new(url.to_s)
      end
    end
  end
end