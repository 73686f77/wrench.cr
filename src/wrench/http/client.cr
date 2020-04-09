class HTTP::Client
  def expect_continue?(expect_continue, status_code : Int32)
    expect_continue && 100_i32 == status_code
  end

  def exec(method : String, path, headers : HTTP::Headers? = nil, body : BodyType = nil, expect_continue : Bool = false)
    exec new_request(method, path, headers, expect_continue ? nil : body, expect_continue) do |response|
      return yield response unless expect_continue? expect_continue, response.status_code

      exec new_request(String.new, String.new, headers, body) do |continue_response|
        yield continue_response
      end
    end
  end

  private def new_request(method, path, headers, body : BodyType, expect_continue : Bool)
    HTTP::Request.new method, path, headers, body, expect_continue: expect_continue
  end
end
