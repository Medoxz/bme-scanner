// tabs working
const tabs = {
  scan: document.getElementById('tab-scan'),
  allergies: document.getElementById('tab-allergies'),
  sources: document.getElementById('tab-sources')
};

function showTab(id) {
  // deactivate all sections
  document.querySelectorAll('section').forEach(sec => sec.classList.remove('active'));
  document.querySelectorAll('header button').forEach(btn => btn.classList.remove('active'));
  
  // activate chosen one
  document.getElementById(id).classList.add('active');
  tabs[id].classList.add('active');
}

// Add event listeners for each tab
tabs.scan.addEventListener('click', () => showTab('scan'));
tabs.allergies.addEventListener('click', () => showTab('allergies'));
tabs.sources.addEventListener('click', () => showTab('sources'));


// Register service worker for PWA installability
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('service-worker.js');
}