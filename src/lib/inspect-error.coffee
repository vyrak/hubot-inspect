class InspectError
  constructor: (status_code, error, error_description) ->
    @name = "InspectError"
    @message = "(#{status_code}) #{error}: #{error_description}"

module.exports = InspectError
