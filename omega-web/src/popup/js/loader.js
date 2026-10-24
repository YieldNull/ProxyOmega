window.OmegaPopup = {};
$script(['js/index.js', 'js/profiles.js', 'js/keyboard.js'], 'om-main');
$script(['js/i18n.js']);
$script('../js/omega_target_popup.js', 'om-target', function() {
  $script('js/style.js', 'om-style')
  function init(){
    OmegaTargetPopup.getProxyScenes(function(err, result) {
      if (err || !result || !result.scenes || !result.scenes.length) return;
      var sceneItem = document.querySelector('.om-scene.om-has-dropdown');
      var toggle = document.getElementById('js-scene-toggle');
      var menu = document.getElementById('js-scene-menu');
      var label = document.getElementById('js-scene-label');
      var current = document.querySelector('.om-scene-current');
      label.textContent = OmegaTargetPopup.getMessage('popup_scene_label') + ':';
      var defaultName = OmegaTargetPopup.getMessage(
        'options_scenes_followDefault');
      var choices = [{id: '', name: defaultName}].concat(result.scenes);
      var active = result.active || '';
      var selected = choices.find(function(scene) {
        return scene.id === active;
      });
      current.textContent = selected ? selected.name : defaultName;
      var pending = false;

      function closeSceneMenu() {
        sceneItem.classList.remove('om-open');
        toggle.setAttribute('aria-expanded', 'false');
      }

      choices.forEach(function(scene) {
        var item = document.createElement('li');
        item.className = 'om-nav-item';
        if (scene.id === active) item.classList.add('om-active');
        var link = document.createElement('a');
        link.href = '#';
        link.setAttribute('role', 'menuitem');
        var icon = document.createElement('span');
        icon.className = 'glyphicon ' +
          (scene.id ? 'glyphicon-globe' : 'glyphicon-transfer');
        icon.style.color = scene.id ? '#9ce' : '#aaa';
        link.appendChild(icon);
        var text = document.createElement('span');
        text.textContent = scene.name;
        link.appendChild(text);
        link.addEventListener('click', function(event) {
          event.preventDefault();
          if (pending) return;
          if (scene.id === active) {
            closeSceneMenu();
            return;
          }
          pending = true;
          OmegaTargetPopup.setActiveProxyScene(scene.id, function(error) {
            if (error) {
              pending = false;
              closeSceneMenu();
              return;
            }
            window.top.close();
          });
        });
        item.appendChild(link);
        menu.appendChild(item);
      });
      toggle.addEventListener('click', function(event) {
        event.preventDefault();
        if (pending) return;
        var open = !sceneItem.classList.contains('om-open');
        document.querySelectorAll('.om-open').forEach(function(item) {
          item.classList.remove('om-open');
        });
        sceneItem.classList.toggle('om-open', open);
        toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
      });
      document.addEventListener('click', function(event) {
        if (!sceneItem.contains(event.target)) closeSceneMenu();
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
