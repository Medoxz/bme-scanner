let cleanedTextGlobal = "";

const imageInput = document.getElementById('imageInput');
const preview = document.getElementById('preview');
const resultEl = document.getElementById('result');
const cleanedResult = document.getElementById('cleaned');

// Enable collapsible sections
document.querySelectorAll('.collapsible-header').forEach(header => {
  header.addEventListener('click', () => {
    const content = header.nextElementSibling;
    const chevron = header.querySelector('.chevron');

    const isOpen = content.classList.contains('open');

    // Toggle content visibility
    if (isOpen) {
      content.classList.remove('open');
      chevron.classList.remove('open');
    } else {
      content.classList.add('open');
      chevron.classList.add('open');
    }
  });
});

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
      'nld', // language
      {
        logger: m => console.log(m) // progress updates
      }
    );

    resultEl.textContent = text.trim() || '(No text detected)';

    cleanedTextGlobal = text
      .replace(/-\n/g, '')           // fix hyphenated words
      .replace(/\n+/g, ' ')          // remove extra newlines
      .replace(/[^a-zA-Z0-9(),.%\s-]/g, '') // remove stray characters
      .replace(/\s+/g, ' ')          // collapse spaces
      .trim()
      .split(/[\s,]+/)          // split by space or comma
      .filter(word => word.length > 1)
      .join(', ')               // re-join with commas
      .replace(/,/g, '\n')          // turn commas into new lines
      .replace(/^\s+/gm, '')              // remove leading spaces on each line

    cleanedResult.textContent = cleanedTextGlobal

    matchAllergens()

    
  } catch (err) {
    console.error(err);
    resultEl.textContent = 'Error reading text.';
  }
})

function matchAllergens() {
  const matchesBox = document.getElementById('matches');
  const altsBox = document.getElementById('alts');

  // if (!cleanedTextGlobal || cleanedTextGlobal.length < 2) {
  //   matchesBox.textContent = "No cleaned text yet.";
  //   altsBox.textContent = "No allergen names loaded yet.";
  //   return;
  // }

  if (!allergenList || allergenList.length === 0) {
    matchesBox.textContent = "No allergen data loaded.";
    altsBox.textContent = "No allergen data loaded.";
    return;
  }

  const selected = Array.from(
    document.querySelectorAll('#allergies input[type="checkbox"]:checked')
  ).map(cb => cb.value);

  if (selected.length === 0) {
    matchesBox.textContent = "No allergies selected.";
    altsBox.textContent = "No allergies selected.";
    return;
  }

  let matches = [];
  let allAlternativeNames = [];

  allergenList.forEach(allergen => {
    if (!selected.includes(allergen.chemical_name)) return;

    const alts = allergen.alternative_names.map(a => a.toLowerCase());
    allAlternativeNames.push(...allergen.alternative_names);

    alts.forEach(name => {
      if (cleanedTextGlobal.includes(name)) {
        matches.push(`${allergen.chemical_name} (matched: "${name}")`);
      }
    });
  });

  // Fill found matches
  matchesBox.textContent =
    (matches.length > 0 && cleanedTextGlobal.length > 0)
      ? "⚠️ Found allergens:\n" + matches.join("\n")
      : "✔️ No allergens found.";

  // Fill alternative search names
  altsBox.textContent =
    allAlternativeNames.length > 0
      ? allAlternativeNames.join("\n")
      : "No alternative names found for selected allergens.";
}