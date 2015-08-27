module Response
  class Base
    def to_json(*args)
      data.to_json(*args)
    end

    def data
      {}
    end

    def response_code
      raise "not implemented"
    end
  end

  class Success < Base
    def initialize(data)
      @data = data
    end

    def data
      @data
    end

    def response_code
      200
    end
  end

  class Failure < Base
    def data
      {
        "error" => {
          "code" => response_code,
          "message" => response_message
        }.merge(extra_error_data)
      }
    end

    def extra_error_data
      {}
    end

    def response_code
      raise "abstract method not implemented"
    end

    def response_message
      raise "abstract method not implemented"
    end
  end

  class NotFound < Failure
    def response_code
      404
    end

    def response_message
      "not found"
    end
  end

  class Unauthorized < Failure
    def response_code
      401
    end

    def response_message
      "unauthorized"
    end
  end

  class UnprocessableEntity < Failure
    def response_code
      422
    end

    def response_message
      "unprocessable entity"
    end
  end

  class MissingRequiredField < UnprocessableEntity
    attr_reader :missing_field_name, :missing_field_message

    def initialize(missing_field_name, missing_field_message = 'required')
      @missing_field_name = missing_field_name
      @missing_field_message = missing_field_message
    end

    def extra_error_data
      {
        "fields" => { missing_field_name => missing_field_message }
      }
    end
  end
end
