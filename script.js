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

// Register service worker for PWA installability
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('service-worker.js');
}