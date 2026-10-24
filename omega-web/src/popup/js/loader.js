window.OmegaPopup = {};
$script(['js/index.js', 'js/profiles.js', 'js/keyboard.js'], 'om-main');
$script(['js/i18n.js']);
$script('../js/omega_target_popup.js', 'om-target', function() {
  $script('js/style.js', 'om-style')
  function init(){
    OmegaTargetPopup.getProxyScenes(function(err, result) {
      if (err || !result || !result.scenes || !result.scenes.length) return;
      var select = document.getElementById('js-scene-select');
      var label = document.getElementById('js-scene-label');
      label.textContent = OmegaTargetPopup.getMessage('options_scenes_active');
      var defaultName = OmegaTargetPopup.getMessage(
        'options_scenes_followDefault');
      var defaultScene = result.scenes.find(function(scene) {
        return scene.id === result.defaultScene;
      });
      if (defaultScene) defaultName += ' (' + defaultScene.name + ')';
      var choices = [{id: '', name: defaultName}]
        .concat(result.scenes);
      choices.forEach(function(scene) {
        var option = document.createElement('option');
        option.value = scene.id;
        option.textContent = scene.name;
        select.appendChild(option);
      });
      select.value = result.active || '';
      select.addEventListener('change', function() {
        select.disabled = true;
        OmegaTargetPopup.setActiveProxyScene(select.value, function(error) {
          if (error) {
            select.disabled = false;
            select.value = result.active || '';
            return;
          }
          window.top.close();
        });
      });
      document.querySelectorAll('.om-scene').forEach(function(el) {
        el.classList.remove('om-hidden');
      });
    });
    chrome.tabs.query({active: true, lastFocusedWindow: true}).then(function(tabs){
      if (tabs.length > 0 && (tabs[0].pendingUrl || tabs[0].url)){
        const activeTab = tabs[0]
        window.OmegaPopup.activeTab = activeTab;
        const reqinfoEl = document.getElementById('js-reqinfo');
        const addruleEl = document.getElementById('js-addrule');
        reqinfoEl.setAttribute('href', '../popup.html?activeTabId=' + activeTab.id + '#!requestInfo')
        addruleEl.setAttribute('href', '../popup.html?activeTabId=' + activeTab.id + '#!addRule')
      }
    }).catch(function(){})
    OmegaTargetPopup.getActivePageInfo(function(err, info) {
      window.OmegaPopup.pageInfo = info;
      $script.done('om-page-info');
    });
    OmegaTargetPopup.getState([
      'availableProfiles',
      'currentProfileName',
      'validResultProfiles',
      'isSystemProfile',
      'currentProfileCanAddRule',
      'proxyNotControllable',
      'externalProfile',
      'showExternalProfile',
      'customCss',
    ], function(err, state) {
      window.OmegaPopup.state = state;
      $script.done('om-state');
    });
  }
  const permissionValue = {origins: ["<all_urls>"]}
  if (globalThis.browser && browser.proxy && browser.proxy.onRequest){
    Promise.all([browser.permissions.contains(permissionValue), browser.extension.isAllowedIncognitoAccess()])
    .then(([sitePermissions, isAllowedIncognitoAccess])=>{
      // chrome.contextMenus check is Android or PC,
      // browser.proxy.settings doesn't support Android
      if (sitePermissions && (!chrome.contextMenus || isAllowedIncognitoAccess)) {
        init();
      } else {
        location.href = 'grant_permissions.html'
      }
    })
  } else {
    init();
  }
});
