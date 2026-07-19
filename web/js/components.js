export function createCard(item) {
    const card = document.getElementById("card-template").content.firstElementChild.cloneNode(true)

    card.href = item.href

    const image = card.querySelector(".card-image")

    image.src = item.image
    image.alt = item.title

    card.querySelector(".card-title").textContent = item.title
    card.querySelector(".card-subtitle").textContent = item.subtitle
    card.querySelector(".card-updated").textContent = `Updated · ${item.updated}`

    return card
}

export function createChip(label, selected, onChange) {
    const chip = document.getElementById("chip-template").content.firstElementChild.cloneNode(true)

    chip.textContent = label

    chip.classList.toggle("selected", selected)

    chip.addEventListener("click", () => onChange(selected ? null : label))

    return chip
}

export function createTab(label, selected, onChange) {
    const tab = document.getElementById("tab-template").content.firstElementChild.cloneNode(true)

    tab.textContent = label.toUpperCase()

    tab.classList.toggle("selected", selected)

    tab.addEventListener("click", () => !selected && onChange(label))

    return tab
}

export function createEmpty(message) {
    const empty = document.getElementById("empty-template").content.firstElementChild.cloneNode(true)

    empty.textContent = message

    return empty
}
