Promise = require 'bluebird'
Octokat = require 'octokat'
request = require 'request-promise'
{p, log} = require 'lightsaber'
{merge, sample, size, sortBy} = require 'lodash'
$ = require 'jquery'
# DataTable = require 'datatables'
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

class Matrix

  ORG = 'ipfs'

  # RAW_GITHUB_SOURCES = [
  #   (repoName, path) -> "https://raw.githubusercontent.com/#{ORG}/#{repoName}/master/#{path}"
  #   (repoName, path) -> "https://rawgit.com/#{ORG}/#{repoName}/master/#{path}"
  #   # (repoName, path) -> "https://raw.githack.com/#{ORG}/#{repoName}/master/#{path}"  # funky error messages on 404
  # ]

  README_BADGES =
    'Travis': (repoName) -> "[![Travis CI](https://travis-ci.org//#{ORG}//#{repoName}.svg?branch=master)](https://travis-ci.org/#{ORG}/#{repoName})"
    'Circle': (repoName) -> "[![Circle CI](https://circleci.com/gh/#{ORG}/#{repoName}.svg?style=svg)](https://circleci.com/gh/#{ORG}/#{repoName})"
    'Made By': -> '[![](https://img.shields.io/badge/made%20by-Protocol%20Labs-blue.svg?style=flat-square)](http://ipn.io)'
    'Project': -> '[![](https://img.shields.io/badge/project-IPFS-blue.svg?style=flat-square)](http://ipfs.io/)'
    'IRC':     -> '[![](https://img.shields.io/badge/freejs-%23ipfs-blue.svg?style=flat-square)](http://webchat.freenode.net/?channels=%23ipfs)'

  README_OTHER =
    'Banner': -> '![](https://cdn.rawgit.com/jbenet/contribute-ipfs-gif/master/img/contribute.gif)'

  README_ITEMS = merge README_BADGES, README_OTHER

  create: ->
    github = new Octokat
      username: "irGAYpwGxP"
      password: "irGAYpwGxPfFtVLmHK84KNyjP"
      # username: "8DvrWa6nBCevZt"
      # password: "wojY4o9yWyRKDN"
    p 111, github.rateLimit.fetch()
    github.orgs(ORG).repos.fetch()
    .then (repos) -> getReadmes repos
    .then -> document repos

  document: (repos) ->
    """
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8">
        <title>IPFS Builds &amp; Infrastructure Checks</title>
        <link rel="stylesheet" type="text/css" href="styles/datatables.css">
        <link rel="stylesheet" type="text/css" href="styles/app.css">
      </head>
      <body>
        <div id="content">
          #{grid repos}
        </div>
      </body>
    </html>
    """

    # $('table').DataTable
    #   paging: false
    #   searching: false

  getReadmes: (repos) ->
    repos = sortBy repos, 'name'
    Promise.map repos, (repo) ->
      repo.readme.read()
      .then (readmeText) -> repo.readmeText = readmeText
      .error (err) -> console.error [".error:", uri, err].join("\n")
      .catch (err) -> console.error [".catch:", uri, err].join("\n")
    # .then -> repos

  grid: renderable (repos) ->
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

  check: renderable (success) ->
    if success
      span class: 'success', -> '✓'
    else
      span class: 'failure', -> '✗'

  travis: renderable (repoName) ->
    a href: "https://travis-ci.org/#{ORG}/#{repoName}", ->
      img src: "https://travis-ci.org/#{ORG}/#{repoName}.svg?branch=master"

  circle: renderable (repoName) ->
    a href: "https://circleci.com/gh/#{ORG}/#{repoName}", ->
      img src: "https://circleci.com/gh/#{ORG}/#{repoName}.svg?style=svg"

module.exports = Matrix
