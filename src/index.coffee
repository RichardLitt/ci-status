Promise = require 'bluebird'
Octokat = require 'octokat'
request = require 'request-promise'
{p, log} = require 'lightsaber'
{merge, sample, size, sortBy} = require 'lodash'
$ = require 'jquery'
DataTable = require 'datatables'
{
  a
  img
  raw
  render
  renderable
  span
  table
  tbody
  td
  th
  thead
  tr
} = require 'teacup'

ORG = 'ipfs'

RAW_GITHUB_SOURCES = [
  (repoName, path) -> "https://raw.githubusercontent.com/#{ORG}/#{repoName}/master/#{path}"
  (repoName, path) -> "https://raw.githack.com/#{ORG}/#{repoName}/master/#{path}"
  (repoName, path) -> "https://rawgit.com/#{ORG}/#{repoName}/master/#{path}"
]

README_BADGES =
  'Travis': (repoName) -> "[![Travis CI](https://travis-ci.org//#{ORG}//#{repoName}.svg?branch=master)](https://travis-ci.org/#{ORG}/#{repoName})"
  'Circle': (repoName) -> "[![Circle CI](https://circleci.com/gh/#{ORG}/#{repoName}.svg?style=svg)](https://circleci.com/gh/#{ORG}/#{repoName})"
  'Made By': -> '[![](https://img.shields.io/badge/made%20by-Protocol%20Labs-blue.svg?style=flat-square)](http://ipn.io)'
  'Project': -> '[![](https://img.shields.io/badge/project-IPFS-blue.svg?style=flat-square)](http://ipfs.io/)'
  'IRC':     -> '[![](https://img.shields.io/badge/freejs-%23ipfs-blue.svg?style=flat-square)](http://webchat.freenode.net/?channels=%23ipfs)'

README_OTHER =
  'Banner': -> '![](https://cdn.rawgit.com/jbenet/contribute-ipfs-gif/master/img/contribute.gif)'

README_ITEMS = merge README_BADGES, README_OTHER

main = ->
  github = new Octokat
    # api throttled per account :(
    # username: "irGAYpwGxP"
    # password: "irGAYpwGxPfFtVLmHK84KNyjP"
    # username: "8DvrWa6nBCevZt"
    # password: "wojY4o9yWyRKDN"
  github.orgs('ipfs').repos.fetch()
  .then (repos) -> getReadmes repos
  .then (repos) -> show matrix repos

getReadmes = (repos) ->
  repos = sortBy repos, 'name'
  Promise.map repos, (repo) ->
    source = 0
    uri = RAW_GITHUB_SOURCES[source](repo.name, 'README.md')
    request {uri}
    .then (readmeText) -> repo.readmeText = readmeText
    .error (err) ->
      console.error [".error:", uri, err].join("\n")
      if err.message.indexOf 'StatusCodeError: 404' isnt -1
        log "Retrying..."
        getReadme ++source
    # githubusercontent
    # StatusCodeError: 404 - Not Found
    #
    # rawgit:
    # StatusCodeError: 404 - <!DOCTYPE html>
    # <html lang="en">
    # <meta charset="utf-8">
    # <title>404 Not Found</title>
    #
    # <h1>404 Not Found</h1>
    # <p>I dunno what you expected, but it ain't here.</p>
    #
    # githack:
    # RequestError: TypeError: Failed to fetch [empty repo]
    # [cors error on missing readme]

    .catch (err) -> console.error [".catch:", uri, err].join("\n")
  .then -> repos

matrix = renderable (repos) ->
  table class: 'stripe order-column compact cell-border', ->
    thead ->
      tr ->
        th ->
        th colspan: 2, -> "Builds"
        th colspan: 2, -> "README.md"
        th colspan: size(README_ITEMS), -> "Badges"
      tr ->
        th class: 'left', -> "IPFS Repo"
        th class: 'left', -> "Travis CI"
        th class: 'left', -> "Circle CI"
        th -> "exists"
        th -> "> 500 chars"
        for name of README_ITEMS
          th -> name
    tbody ->
      for repo in repos
        tr ->
          td class: 'left', ->
            a href: "https://github.com/#{ORG}/#{repo.name}", -> repo.name
          td class: 'left', -> travis repo.name
          td class: 'left', -> circle repo.name
          td -> check repo.readmeText?
          td -> check(repo.readmeText? and repo.readmeText.length > 500)
          for name, template of README_ITEMS
            expectedMarkdown = template repo.name
            td -> check (repo.readmeText? and repo.readmeText?.indexOf(expectedMarkdown) isnt -1)

check = renderable (success) ->
  if success
    span class: 'success', -> '✓'
  else
    span class: 'failure', -> '✗'

travis = renderable (repoName) ->
  a href: "https://travis-ci.org/#{ORG}/#{repoName}", ->
    img src: "https://travis-ci.org/#{ORG}/#{repoName}.svg?branch=master"

circle = renderable (repoName) ->
  a href: "https://circleci.com/gh/#{ORG}/#{repoName}", ->
    img src: "https://circleci.com/gh/#{ORG}/#{repoName}.svg?style=svg"

show = (html) ->
  $('#content').html(html)
  $('table').DataTable
    paging: false
    searching: false

main()
