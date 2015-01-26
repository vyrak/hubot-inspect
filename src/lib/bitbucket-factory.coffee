HubotAppError = require("./inspect-error")
OAuth = require("oauth").OAuth
Promise = require("bluebird")

base_url = "https://bitbucket.org/api/1.0"

module.exports = (options) ->
  client = new OAuth(
    null
    null
    options.consumer_key
    options.consumer_secret
    "1.0"
    null
    "HMAC-SHA1"
  )
  (path) ->
    url = "#{base_url}#{path}"
    new Promise (resolve, reject) ->
      client.get url, options.oauth_token, options.oauth_secret, (err, data, res) ->
        if err
          reject new HubotAppError(err.statusCode, "Bitbucket Error", err.data)
        else
          resolve data: JSON.parse(data), response: res
