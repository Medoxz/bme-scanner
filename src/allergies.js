// allergies.js — Handles loading and rendering allergens

async function loadAllergens() {
  try {
    const response = await fetch('data/alternative_names_asz.json');  // adjust path if needed
    const allergens = await response.json();

    const allergiesSection = document.getElementById('allergies');

    const listContainer = document.createElement('div');
    listContainer.className = "allergy-list";

    allergens.forEach(item => {
      const wrapper = document.createElement('label');
      wrapper.className = "allergy-item";

      const checkbox = document.createElement('input');
      checkbox.type = "checkbox";
      checkbox.value = item.chemical_name;

      const text = document.createElement('span');
      text.textContent = item.chemical_name;

      wrapper.appendChild(checkbox);
      wrapper.appendChild(text);

      listContainer.appendChild(wrapper);
    });

    allergiesSection.appendChild(listContainer);

  } catch (err) {
    console.error("Failed to load allergens.json:", err);
  }
}

// Automatically load allergens when the script is loaded
loadAllergens();