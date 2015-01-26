R = require("ramda")
Promise = require("bluebird")
bitbucket_factory = require("./bitbucket-factory")
cloud66_factory = require("./cloud66-factory")

inspections = R.curry (repo, deployment) ->
  repo_slug: repo.slug
  repo_sha: repo.raw_node
  stack_name: deployment.stack_name
  stack_sha: deployment.git_hash
  environment: deployment.environment
  is_different: repo.raw_node != deployment.git_hash

module.exports = (http, options) ->
  bitbucket = bitbucket_factory(options.bitbucket)
  cloud66 = cloud66_factory(http, options.cloud66)

  master_branch = (repo) ->
    bitbucket("/repositories/#{options.bitbucket.account_name}/#{repo.slug}/branches").then (result) ->
      R.mixin(result.data.master, slug: repo.slug)
  latest_deployment = (stack) ->
    cloud66("/stacks/#{stack.uid}/deployments").then (result) ->
      R.mixin(R.head(result.response), stack_name: stack.name, environment: stack.environment)

  (repo_slug, environment) ->
    masters_promise = if repo_slug
      master_branch(slug: repo_slug).then((master) -> [master])
    else
      bitbucket("/user/repositories").then (result) ->
        Promise.all R.map(master_branch, result.data)

    stack_deployments_promise = cloud66("/stacks").then (result) ->
      Promise.all R.map(latest_deployment, result.response)

    Promise.all([masters_promise, stack_deployments_promise]).spread (masters, deployments) ->
      include_deployment = if repo_slug then ((deployment) -> deployment.stack_name.lastIndexOf("#{repo_slug}-") == 0) else R.T
      include_environment = if environment then R.propEq("environment", environment) else R.T
      inspect = (repo) ->
        repo_deployments = R.filter(R.and(include_deployment, include_environment), deployments)
        R.map(inspections(repo), repo_deployments)

      R.flatten(R.map(inspect, masters))
