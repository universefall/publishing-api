module Query
  class Response
    attr_reader :response_code

    def initialize(data, response_code)
      @data = data
      @response_code = response_code
    end

    def to_json(*args)
      @data.to_json(*args)
    end
  end

  class SuccessResponse < Response
    def initialize(data)
      super(data, 200)
    end
  end

  class NotFoundResponse < Response
    def initialize
      super({error: {code: 404, message: "not found"}}, 404)
    end
  end
end
