class HTTP::Request
  property method : String
  property headers : Headers
  getter body : IO?
  property version : String
  property expect_continue : Bool
  @cookies : Cookies?
  @query_params : Params?
  @uri : URI?

  # The network address that sent the request to an HTTP server.
  #
  # `HTTP::Server` will try to fill this property, and its value
  # will have a format like "IP:port", but this format is not guaranteed.
  # Middlewares can overwrite this value.
  #
  # This property is not used by `HTTP::Client`.
  property remote_address : String?

  def self.new(method : String, resource : String, headers : Headers? = nil, body : String | Bytes | IO | Nil = nil, expect_continue : Bool = false, version = "HTTP/1.1")
    # Duplicate headers to prevent the request from modifying data that the user might hold.
    new method, resource, headers.try(&.dup), body, expect_continue: expect_continue, version: version, internal: nil
  end

  private def initialize(@method : String, @resource : String, headers : Headers? = nil, body : String | Bytes | IO | Nil = nil, @expect_continue : Bool = false, @version = "HTTP/1.1", *, internal)
    @headers = headers || Headers.new
    self.body = body
  end

  def self.new(method : String, resource : String, headers : Headers? = nil, body : String | Bytes | IO | Nil = nil, version = "HTTP/1.1")
    # Duplicate headers to prevent the request from modifying data that the user might hold.
    new method, resource, headers.try(&.dup), body, expect_continue: false, version: version, internal: nil
  end

  private def initialize(@method : String, @resource : String, headers : Headers? = nil, body : String | Bytes | IO | Nil = nil, @version = "HTTP/1.1", *, internal)
    @headers = headers || Headers.new
    @expect_continue = false
    self.body = body
  end

  def connect?
    method == "CONNECT"
  end

  def self.parse_string_port(text : String)
    return unless port = text.to_i?

    port if port < 65536_i32
  end

  def self.get_port_from_text(text : String)
    uri = URI.parse text

    # Try - No.1
    return uri.port if uri.port

    # Try - No.2
    port = parse_string_port uri.path
    return port if port

    # Try - No.3
    host_port = text.rpartition ":"
    port = parse_string_port host_port.last
    return port if port

    # Try - No.4
    host_port = uri.path.rpartition ":"
    port = parse_string_port host_port.last
    return port if port

    # Finally
    scheme = uri.scheme || String.new
    "https" == scheme.downcase ? 443_i32 : 80_i32
  end

  def self.get_host_from_text(text : String)
    uri = URI.parse text

    return uri.host if uri.host
    return uri.scheme if uri.scheme

    host_port = text.rpartition ":"
    host = host_port.first
    return host unless host.empty?
  end

  def connect_host
    return unless address = @resource

    Request.get_host_from_text address
  end

  def header_host
    return unless address = @headers["Host"]?

    Request.get_host_from_text address
  end

  def connect_port
    return unless address = @resource

    Request.get_port_from_text address
  end

  def header_port
    return unless address = @headers["Host"]?

    Request.get_port_from_text address
  end

  def body=(@body : Nil)
    return if @expect_continue

    @headers["Content-Length"] = "0" if @method == "POST" || @method == "PUT"
  end

  def keep_alive=(value : Bool)
    return unless value

    @headers["Connection"] = "keep-alive"
  end

  def header_host=(value : String)
    @headers["Host"] = value
  end

  def content_length
    @headers["Content-Length"].to_i64? || 0_i64
  end
end
