angular.module('omega').controller 'ScenesCtrl', ($scope, $window,
  trFilter) ->
  $scope.scenes = $scope.options['-proxyScenes'] ? []
  $scope.activeScene = $scope.options['-activeProxyScene'] ? ''
  $scope.defaultScene = $scope.options['-defaultProxyScene'] ? ''
  baseChoice = {id: '', name: trFilter('options_scenes_base')}
  followChoice = {id: '', name: trFilter('options_scenes_followDefault')}
  $scope.defaultChoices = [baseChoice].concat($scope.scenes)
  $scope.sceneChoices = [followChoice].concat($scope.scenes)

  $scope.selectActiveScene = ->
    $scope.options['-activeProxyScene'] = $scope.activeScene

  $scope.selectDefaultScene = ->
    $scope.options['-defaultProxyScene'] = $scope.defaultScene

  $scope.addScene = ->
    name = $scope.newSceneName?.trim()
    return unless name
    id = 'scene-' + Date.now().toString(36) + '-' +
      Math.random().toString(36).slice(2, 8)
    unless $scope.options['-proxyScenes']?
      $scope.options['-proxyScenes'] = $scope.scenes
    $scope.scenes.push({id: id, name: name})
    $scope.defaultChoices = [baseChoice].concat($scope.scenes)
    $scope.sceneChoices = [followChoice].concat($scope.scenes)
    $scope.newSceneName = ''

  $scope.removeScene = (scene) ->
    index = $scope.scenes.indexOf(scene)
    return if index < 0
    return unless $window.confirm(trFilter('options_scenes_deleteConfirm'))
    $scope.scenes.splice(index, 1)
    if $scope.options['-activeProxyScene'] == scene.id
      $scope.options['-activeProxyScene'] = ''
      $scope.activeScene = ''
    if $scope.options['-defaultProxyScene'] == scene.id
      $scope.options['-defaultProxyScene'] = ''
      $scope.defaultScene = ''
    OmegaPac.Profiles.each $scope.options, (key, profile) ->
      if profile.sceneProfiles?
        delete profile.sceneProfiles[scene.id]
    $scope.defaultChoices = [baseChoice].concat($scope.scenes)
    $scope.sceneChoices = [followChoice].concat($scope.scenes)
