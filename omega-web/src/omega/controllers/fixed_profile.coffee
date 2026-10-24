angular.module('omega').controller 'FixedProfileCtrl', ($scope, $modal,
  trFilter) ->
  $scope.urlSchemes = ['', 'http', 'https', 'ftp']
  $scope.showAdvanced = false
  $scope.schemeDisp =
    '': null
    'http': 'http://'
    'https': 'https://'
    'ftp': 'ftp://'

  proxyProperties =
    '': 'fallbackProxy'
    'http': 'proxyForHttp'
    'https': 'proxyForHttps'
    'ftp': 'proxyForFtp'
  defaultPort =
    'http': 80
    'https': 443
    'socks4': 1080
    'socks5': 1080

  $scope.optionsForScheme = {}
  for scheme in $scope.urlSchemes
    defaultLabel =
      if scheme
        trFilter('options_protocol_useDefault')
      else
        trFilter('options_protocol_direct')
    $scope.optionsForScheme[scheme] = [
      {label: defaultLabel, value: undefined},
      {label: 'HTTP', value: 'http'},
      {label: 'HTTPS', value: 'https'},
      {label: 'SOCKS4', value: 'socks4'},
      {label: 'SOCKS5', value: 'socks5'},
    ]

  makeRow = (id, name, profile) ->
    bypass = profile.bypassList ? []
    row =
      id: id
      name: name
      profile: profile
      proxyEditors: {}
      proxyDNS: profile.proxyDNS ? true
      bypassList: (item.pattern for item in bypass).join('\n')
    for scheme in $scope.urlSchemes
      row.proxyEditors[scheme] = profile[proxyProperties[scheme]] ? {}
      $scope.showAdvanced = true if scheme and
        profile[proxyProperties[scheme]]?
    row

  $scope.sceneRows = []
  $scope.$watch 'profile', (profile) ->
    return unless profile
    $scope.sceneRows = [makeRow('', trFilter('options_scenes_base'), profile)]
    for scene in ($scope.options['-proxyScenes'] ? [])
      override = profile.sceneProfiles?[scene.id]
      if override
        $scope.sceneRows.push(makeRow(scene.id, scene.name, override))

  $scope.availableScenes = ->
    return [] unless $scope.profile
    scenes = $scope.options['-proxyScenes'] ? []
    scenes.filter (scene) ->
      not $scope.profile.sceneProfiles?[scene.id]

  $scope.isActiveScene = (row) ->
    active = $scope.options['-activeProxyScene'] ||
      $scope.options['-defaultProxyScene'] || ''
    return true if row.id == active
    row.id == '' and not $scope.profile.sceneProfiles?[active]

  $scope.addScene = (scene) ->
    return unless scene? and $scope.profile
    return if $scope.profile.sceneProfiles?[scene.id]
    override = angular.copy($scope.profile)
    delete override.sceneProfiles
    delete override.name
    delete override.profileType
    delete override.color
    delete override.revision
    $scope.profile.sceneProfiles ?= {}
    $scope.profile.sceneProfiles[scene.id] = override
    $scope.sceneRows.push(makeRow(scene.id, scene.name, override))

  $scope.updateProxy = (row, scheme) ->
    prop = proxyProperties[scheme]
    proxy = row.proxyEditors[scheme]
    unless proxy.scheme
      delete row.profile[prop]
      row.proxyEditors[scheme] = {}
      return
    unless proxy.port
      fallback = row.proxyEditors['']
      if scheme and proxy.scheme == fallback.scheme
        proxy.port = fallback.port
      proxy.port ?= defaultPort[proxy.scheme]
    proxy.host ?= row.proxyEditors[''].host ? 'example.com'
    row.profile[prop] = proxy

  $scope.updateProxyDNS = (row) ->
    row.profile.proxyDNS = row.proxyDNS

  $scope.updateBypassList = (row) ->
    row.profile.bypassList =
      for entry in row.bypassList.split(/\r?\n/) when entry
        conditionType: 'BypassCondition'
        pattern: entry

  socks5AuthSupported = (browser?.proxy?.onRequest?)
  $scope.authSupported =
    'http': true
    'https': true
    'socks5': socks5AuthSupported

  $scope.isProxyAuthActive = (row, scheme) ->
    row.profile.auth?[proxyProperties[scheme]]?

  $scope.editProxyAuth = (row, scheme) ->
    prop = proxyProperties[scheme]
    proxy = row.profile[prop]
    return unless proxy?.scheme
    scope = $scope.$new('isolate')
    scope.proxy = proxy
    auth = row.profile.auth?[prop]
    scope.auth = auth && angular.copy(auth)
    scope.authSupported = $scope.authSupported[proxy.scheme]
    scope.protocolDisp = proxy.scheme
    $modal.open(
      templateUrl: 'partials/fixed_auth_edit.html'
      scope: scope
      size: if scope.authSupported then 'sm' else 'lg'
    ).result.then (auth) ->
      if not auth?.username
        if row.profile.auth
          row.profile.auth[prop] = undefined
      else
        row.profile.auth ?= {}
        row.profile.auth[prop] = auth
