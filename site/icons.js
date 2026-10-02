const grid = document.querySelector('#icon-grid');
const search = document.querySelector('#search');
let icons = [], light = false;
function render() {
  const query = search.value.trim().toLowerCase();
  const matches = icons.filter(i => `${i.name} ${i.category}`.toLowerCase().includes(query));
  grid.replaceChildren(...matches.map(icon => {
    const card = document.createElement('article');
    card.className = 'icon-card';
    const img = document.createElement('img');
    img.src = `assets/icons/${light ? 'black' : 'white'}/${icon.name}.svg`;
    img.alt = ''; img.width = 24; img.height = 24;
    const title = document.createElement('h2'); title.textContent = icon.name;
    const category = document.createElement('small'); category.textContent = icon.category;
    const links = document.createElement('div'); links.className = 'icon-downloads';
    for (const tone of ['black', 'white']) {
      const link = document.createElement('a');
      link.href = `assets/icons/${tone}/${icon.name}.svg`;
      link.download = `ghost-${icon.name}-${tone}.svg`;
      link.textContent = tone;
      link.setAttribute('aria-label', `Download ${icon.name}, ${tone} SVG`);
      links.append(link);
    }
    card.append(img, title, category, links); return card;
  }));
  grid.classList.toggle('light', light);
  document.querySelector('#count').textContent = `${matches.length} / ${icons.length} icons`;
  document.querySelector('#empty').hidden = matches.length !== 0;
}
search.addEventListener('input', render);
for (const id of ['dark', 'light']) document.querySelector(`#${id}`).addEventListener('click', () => {
  light = id === 'light';
  document.querySelector('#light').setAttribute('aria-pressed', String(light));
  document.querySelector('#dark').setAttribute('aria-pressed', String(!light));
  render();
});
fetch('assets/icons/manifest.json').then(r => {
  if (!r.ok) throw new Error('Manifest unavailable');
  return r.json();
}).then(data => { icons = data; render(); }).catch(() => {
  document.querySelector('#count').textContent = 'Icons could not be loaded. Please reload.';
});
