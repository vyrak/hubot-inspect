HubotAppError = require("./inspect-error")
Promise = require("bluebird")

base_url = "https://app.cloud66.com/api/3"

module.exports = (http, options) ->
  (path) ->
    url = "#{base_url}#{path}"
    new Promise (resolve, reject) ->
      get = http(url)
        .header("Accept", "application/json")
        .header("Authorization", "Bearer #{options.token}").get()

      get (err, res, body) ->
        if err
          reject err
        else if res.statusCode >= 400
          reject new HubotAppError(res.statusCode, body.error, body.error_description)
        else
          resolve JSON.parse(body)
