class HTTP::Request
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

  def self.parse_port(text : String)
    return unless port = text.to_i?

    port if port <= 65535_i32
  end

  def self.get_port_from_text(text : String) : Int32?
    uri = URI.parse text

    return uri.port if uri.port

    port = parse_port uri.path
    return port if port

    host_port = text.rpartition ":"
    port = parse_port host_port.last
    return port if port

    host_port = uri.path.rpartition ":"
    port = parse_port host_port.last
    return port if port

    scheme = uri.scheme || String.new
    return 443_i32 if "https" == scheme.downcase
    return 80_i32 if "http" == scheme.downcase

    nil
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

  def regular_port
    header_port || connect_port
  end

  def body=(@body : Nil)
    return if @expect_continue

    @headers["Content-Length"] = "0" if @method == "POST" || @method == "PUT"
  end

  def header_keep_alive=(value : Bool)
    return unless value

    @headers["Connection"] = "keep-alive"
  end

  def header_host=(value : String)
    @headers["Host"] = value
  end

  def content_length
    @headers["Content-Length"].to_i64? || 0_i64
  end

  def encoding? : Bool
    return false unless _compress_type = compress_type
    return false if _compress_type.identity?

    true
  end

  def compress_type : HTTP::CompressType?
    return unless encoding = @headers["Accept-Encoding"]?

    split = encoding.split ", "
    return unless first = split.first?

    HTTP::CompressType.parse? first
  end

  def to_io(io, without_body : Bool)
    io << @method << ' ' << resource << ' ' << @version << "\r\n"
    cookies = @cookies
    headers = cookies ? cookies.add_request_headers(@headers) : @headers
    return if without_body

    HTTP.serialize_headers_and_body io, headers, nil, @body, @version
  end

  def serialize_headers_and_body(io)
    HTTP.serialize_headers_and_body io, headers, nil, @body, @version
  end
end
