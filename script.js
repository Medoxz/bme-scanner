const imageInput = document.getElementById('imageInput');
const preview = document.getElementById('preview');
const resultEl = document.getElementById('result');
const cleanedResult = document.getElementById('cleaned');

imageInput.addEventListener('change', async (event) => {
  const file = event.target.files[0];
  if (!file) return;

  // Show a preview
  const imgURL = URL.createObjectURL(file);
  preview.src = imgURL;
  preview.style.display = 'block';

  resultEl.textContent = 'Reading text... ⏳';

  try {
    // Run OCR using Tesseract.js
    const { data: { text } } = await Tesseract.recognize(
      file,
      'eng', // language
      {
        logger: m => console.log(m) // progress updates
      }
    );

    resultEl.textContent = text.trim() || '(No text detected)';

    cleanedResult.textContent = text
      .replace(/-\n/g, '')           // fix hyphenated words
      .replace(/\n+/g, ' ')          // remove extra newlines
      .replace(/[^a-zA-Z0-9(),.%\s-]/g, '') // remove stray characters
      .replace(/\s+/g, ' ')          // collapse spaces
      .trim()
      .split(/[\s,]+/)          // split by space or comma
      .filter(word => word.length > 1)
      .join(', ')               // re-join with commas
      .replace(/,/g, '\n')          // turn commas into new lines
  } catch (err) {
    console.error(err);
    resultEl.textContent = 'Error reading text.';
  }
});

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