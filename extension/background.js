// Background script for Socio.io content moderation extension
console.log("Background script loaded");

// Extension state
let state = {
  enabled: true,
  textFiltered: 0,
  imagesFiltered: 0,
  backendRunning: false,
  nativeHostConnected: false
};

// Native messaging host connection
let nativePort = null;

// Connect to the native messaging host
function connectToNativeHost() {
  try {
    console.log("Attempting to connect to native messaging host...");
    
    // Check if we've already tried and failed multiple times
    if (state.nativeHostFailedAttempts && state.nativeHostFailedAttempts > 3) {
      console.log("Too many failed attempts to connect to native host. Giving up and using direct backend checks.");
      return false;
    }
    
    nativePort = chrome.runtime.connectNative("com.socioio.contentfilter");
    
    nativePort.onMessage.addListener(function(message) {
      console.log("Received message from native host:", message);
      
      // Reset failed attempts counter on successful connection
      state.nativeHostFailedAttempts = 0;
      
      if (message.action === "backend_status") {
        state.backendRunning = message.result.status === "running" || message.result.status === "started" || message.result.status === "already_running";
        state.nativeHostConnected = true;
        
        console.log("Backend status updated:", state.backendRunning);
        
        // Notify any content scripts that the backend is running
        chrome.tabs.query({}, function(tabs) {
          for (let tab of tabs) {
            try {
              chrome.tabs.sendMessage(tab.id, {
                action: "backendStatusChanged", 
                running: state.backendRunning
              });
            } catch (e) {
              // Ignore errors for tabs that don't have our content script
            }
          }
        });
      }
    });
    
    nativePort.onDisconnect.addListener(function() {
      const error = chrome.runtime.lastError;
      console.log("Native host disconnected:", error);
      state.nativeHostConnected = false;
      state.backendRunning = false;
      nativePort = null;
      
      // Increment failed attempts counter
      state.nativeHostFailedAttempts = (state.nativeHostFailedAttempts || 0) + 1;
      
      // Try to reconnect after a delay, with increasing backoff
      const delay = Math.min(5000 * state.nativeHostFailedAttempts, 30000);
      console.log(`Will try to reconnect in ${delay/1000} seconds (attempt ${state.nativeHostFailedAttempts})`);
      setTimeout(connectToNativeHost, delay);
      
      // Fall back to direct backend checks
      checkBackendDirectly();
    });
    
    // Check the backend status
    nativePort.postMessage({action: "check_backend"});
    
    return true;
  } catch (e) {
    console.error("Error connecting to native host:", e);
    state.nativeHostConnected = false;
    nativePort = null;
    
    // Increment failed attempts counter
    state.nativeHostFailedAttempts = (state.nativeHostFailedAttempts || 0) + 1;
    
    // Fall back to direct backend checks
    checkBackendDirectly();
    
    return false;
  }
}

// Check backend status directly via HTTP
function checkBackendDirectly() {
  console.log("Checking backend status directly via HTTP...");
  
  fetch('http://127.0.0.1:5000/ping')
    .then(response => response.json())
    .then(data => {
      console.log("Backend is running (direct check):", data);
      state.backendRunning = true;
      
      // Notify any content scripts that the backend is running
      chrome.tabs.query({}, function(tabs) {
        for (let tab of tabs) {
          try {
            chrome.tabs.sendMessage(tab.id, {
              action: "backendStatusChanged", 
              running: true
            });
          } catch (e) {
            // Ignore errors for tabs that don't have our content script
          }
        }
      });
    })
    .catch(error => {
      console.log("Backend is not running (direct check):", error);
      state.backendRunning = false;
      
      // Show a notification to the user
      if (!state.backendNotificationShown) {
        chrome.notifications.create({
          type: 'basic',
          iconUrl: 'images/icon128.png',
          title: 'Socio.io Backend Not Running',
          message: 'Please start the backend manually by running start_backend.bat',
          priority: 2
        });
        
        state.backendNotificationShown = true;
      }
    });
    
  // Schedule another check after 30 seconds
  setTimeout(checkBackendDirectly, 30000);
}

// Start the backend via the native messaging host
function startBackend() {
  if (!nativePort) {
    if (!connectToNativeHost()) {
      console.error("Cannot start backend: Native host not connected");
      return false;
    }
  }
  
  console.log("Requesting backend start...");
  nativePort.postMessage({action: "start_backend"});
  return true;
}

// Listen for installation
chrome.runtime.onInstalled.addListener(function() {
  // Set default values
  chrome.storage.local.set({
    enabled: true,
    textFiltered: 0,
    imagesFiltered: 0
  });
  
  console.log('Socio.io Content Moderation extension installed successfully');
  
  // Connect to the native messaging host
  connectToNativeHost();
});

// Initialize counters from storage
function initCounters() {
  chrome.storage.local.get(['textFiltered', 'imagesFiltered'], function(result) {
    state.textFiltered = result.textFiltered || 0;
    state.imagesFiltered = result.imagesFiltered || 0;
    
    // Update badge with current counts
    updateBadge();
  });
}

// Update the extension badge with the number of filtered items
function updateBadge() {
  const total = state.textFiltered + state.imagesFiltered;
  
  if (total > 0) {
    // Format the badge text - if over 99, show 99+
    const badgeText = total > 99 ? '99+' : total.toString();
    
    // Set the badge text
    chrome.action.setBadgeText({ text: badgeText });
    
    // Set badge background color
    chrome.action.setBadgeBackgroundColor({ color: '#4285f4' });
  } else {
    // Clear the badge if no items filtered
    chrome.action.setBadgeText({ text: '' });
  }
}

// Call initialization
initCounters();

// Listen for messages from content script or popup
chrome.runtime.onMessage.addListener(function(message, sender, sendResponse) {
  console.log("Background script received message:", message);
  
  // Handle different message types
  if (message.action === 'updateStats') {
    // Update statistics
    const type = message.type;
    const count = message.count || 1;
    
    console.log(`Background: Received updateStats for ${type}, count=${count}`);
    
    chrome.storage.local.get([type + 'Filtered'], function(result) {
      const current = parseInt(result[type + 'Filtered']) || 0;
      const newCount = current + count;
      
      console.log(`Background: Updating ${type}Filtered from ${current} to ${newCount}`);
      
      // Update local state
      state[type + 'Filtered'] = newCount;
      
      // Store in persistent storage
      chrome.storage.local.set({ 
        [type + 'Filtered']: newCount 
      }, function() {
        console.log(`Background: Successfully updated ${type}Filtered to ${newCount}`);
        
        // Double-check the update
        chrome.storage.local.get([type + 'Filtered'], function(checkResult) {
          console.log(`Background: Verified ${type}Filtered is now ${checkResult[type + 'Filtered']}`);
        });
      });
      
      // Update the badge
      updateBadge();
      
      sendResponse({success: true, newCount: newCount});
    });
    
    return true; // Keep the messaging channel open for async response
  }
  
  // Special handler for direct image stats update
  if (message.action === 'directImageUpdate') {
    console.log('Background: Received direct image update request');
    
    chrome.storage.local.get(['imagesFiltered'], function(result) {
      const current = parseInt(result.imagesFiltered) || 0;
      const newCount = current + 1;
      
      console.log(`Background: Directly updating imagesFiltered from ${current} to ${newCount}`);
      
      // Update local state
      state.imagesFiltered = newCount;
      
      // Store in persistent storage
      chrome.storage.local.set({ 
        'imagesFiltered': newCount 
      }, function() {
        console.log(`Background: Successfully updated imagesFiltered to ${newCount}`);
      });
      
      // Update the badge
      updateBadge();
      
      sendResponse({success: true, newCount: newCount});
    });
    
    return true; // Keep the messaging channel open for async response
  }
  
  // Handle resetting stats
  if (message.action === 'resetStats') {
    chrome.storage.local.set({
      textFiltered: 0,
      imagesFiltered: 0
    });
    
    state.textFiltered = 0;
    state.imagesFiltered = 0;
    
    // Update the badge
    updateBadge();
    
    sendResponse({success: true});
    return true;
  }
  
  // Handle status check requests
  if (message.action === 'getStatus') {
    sendResponse({
      enabled: state.enabled,
      textFiltered: state.textFiltered,
      imagesFiltered: state.imagesFiltered,
      backendRunning: state.backendRunning,
      nativeHostConnected: state.nativeHostConnected,
      status: "Background script is active"
    });
    
    return true;
  }
  
  // Handle content script activation notification
  if (message.action === 'contentScriptActive') {
    console.log("Content script is active on:", message.url);
    
    // If the backend is not running, try to start it
    if (!state.backendRunning) {
      startBackend();
    }
    
    // Send the current backend status to the content script
    sendResponse({
      status: "Background acknowledged content script",
      backendRunning: state.backendRunning
    });
    
    return true;
  }
  
  // Handle backend start request
  if (message.action === 'startBackend') {
    const result = startBackend();
    sendResponse({success: result});
    return true;
  }
  
  // Handle backend status check
  if (message.action === 'checkBackendStatus') {
    if (nativePort) {
      nativePort.postMessage({action: "check_backend"});
    }
    
    sendResponse({
      backendRunning: state.backendRunning,
      nativeHostConnected: state.nativeHostConnected
    });
    
    return true;
  }
  
  // Default response
  sendResponse({status: "Background script received message"});
  return true;
});