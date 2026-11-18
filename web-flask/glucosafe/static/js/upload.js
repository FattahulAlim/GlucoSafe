document.addEventListener("DOMContentLoaded", function () {
  const input = document.getElementById("csv_file");
  const preview = document.getElementById("selected-file");

  if (!input || !preview) return;

  input.addEventListener("change", function () {
    const file = input.files && input.files[0];

    if (!file) {
      preview.textContent = "Belum ada file dipilih";
      return;
    }

    const sizeMb = (file.size / (1024 * 1024)).toFixed(2);
    preview.textContent = `Dipilih: ${file.name} (${sizeMb} MB)`;
  });
});
