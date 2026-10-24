chai = require 'chai'
should = chai.should()

describe 'FixedProfileCtrl scenes', ->
  controller = null

  before ->
    global.angular =
      module: ->
        controller: (name, callback) ->
          controller = callback
      copy: (value) -> JSON.parse(JSON.stringify(value))
    require '../src/omega/controllers/fixed_profile.coffee'

  after ->
    delete global.angular

  makeScope = ->
    profile =
      name: 'proxy'
      profileType: 'FixedProfile'
      fallbackProxy:
        scheme: 'socks5'
        host: '192.168.2.1'
        port: 7897
    scene = {id: 'home', name: 'Home'}
    scope =
      profile: profile
      options:
        '+proxy': profile
        '-proxyScenes': [scene]
      $watch: (expression, callback) ->
        scope.onProfileChange = callback
        callback(scope.profile)
    controller(scope, {}, (key) -> key)
    {scope, scene}

  it 'adds a scene row without replacing the base proxy', ->
    {scope, scene} = makeScope()
    scope.sceneRows.length.should.equal(1)
    scope.options['-activeProxyScene'] = 'home'
    scope.isActiveScene(scope.sceneRows[0]).should.be.true
    scope.addScene(scene)
    scope.sceneRows.length.should.equal(2)
    scope.isActiveScene(scope.sceneRows[1]).should.be.true
    scope.availableScenes().length.should.equal(0)
    sceneRow = scope.sceneRows[1]
    sceneRow.proxyEditors[''].host = '10.0.0.2'
    scope.profile.fallbackProxy.host.should.equal('192.168.2.1')
    scope.profile.sceneProfiles.home.fallbackProxy.host.should.equal('10.0.0.2')

  it 'rebinds rows after saving replaces the profile object', ->
    {scope, scene} = makeScope()
    scope.addScene(scene)
    saved = JSON.parse(JSON.stringify(scope.options))
    scope.options = saved
    scope.profile = saved['+proxy']
    scope.onProfileChange(scope.profile)
    sceneRow = scope.sceneRows[1]
    sceneRow.proxyEditors[''].host = '10.0.0.3'
    scope.options['+proxy'].sceneProfiles.home.fallbackProxy.host
      .should.equal('10.0.0.3')
