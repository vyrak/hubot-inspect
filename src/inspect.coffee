# Description:
#   See what's up with all the apps.
#
# Configuration:
#   HUBOT_CLOUD66_TOKEN
#   HUBOT_BITBUCKET_ACCOUNT_NAME
#   HUBOT_BITBUCKET_CONSUMER_KEY
#   HUBOT_BITBUCKET_CONSUMER_SECRET
#   HUBOT_BITBUCKET_OAUTH_TOKEN
#   HUBOT_BITBUCKET_OAUTH_TOKEN_SECRET
#
# Commands:
#   hubot inspect app - Compares all repos' version with each repos' respective deployed stacks' version of all environments
#   hubot inspect app <repo> - Compares matching repo's version with deployed stacks' version of all environments
#   hubot inspect app <repo> <environment> - Compares matching repo's version with deployed stacks' version of given environment

{ filter
  identity
  join
  map
} = require("ramda")
inspect_factory = require("./lib/inspect-factory")

account_name = process.env.HUBOT_BITBUCKET_ACCOUNT_NAME
inspect_options =
  bitbucket:
    account_name: account_name
    consumer_key: process.env.HUBOT_BITBUCKET_CONSUMER_KEY
    consumer_secret: process.env.HUBOT_BITBUCKET_CONSUMER_SECRET
    oauth_token: process.env.HUBOT_BITBUCKET_OAUTH_TOKEN
    oauth_secret: process.env.HUBOT_BITBUCKET_OAUTH_TOKEN_SECRET
  cloud66:
    token: process.env.HUBOT_CLOUD66_TOKEN

module.exports = (robot) ->
  inspect = inspect_factory(robot.http, inspect_options)

  robot.respond /inspect app(?:\s+(.*))?/i, (msg) ->
    parameters = msg.match[1]?.split(" ") || []
    [repo_slug, environment] = filter identity, parameters

    inspect(repo_slug, environment).then((inspections) ->
      line = (inspection) ->
        state = if inspection.is_different
          "different (https://bitbucket.org/#{account_name}/#{inspection.repo_slug}/compare/master..#{inspection.stack_sha}#diff)"
        else
          "up to date"
        ["#{inspection.stack_name}(#{inspection.environment}) is #{state}"]

      lines = map line, inspections
      msg.reply join("\n", lines)
    ).catch((e) ->
      msg.reply "something went awry, can't inspect at this time", e.name, e.message, e.stack
    )

  robot.error (err, msg) -> msg.reply err if msg?
