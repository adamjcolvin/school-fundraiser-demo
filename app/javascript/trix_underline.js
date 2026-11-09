import "trix"
import "@rails/actiontext"

// Trix ships bold and italic. Underline is a text attribute we register
// ourselves, stored as a <u> tag. Action Text is told to allow that tag
// in config/initializers/action_text.rb.
const underline = {
  tagName: "u",
  inheritable: true,
  parser(element) {
    return element.tagName === "U"
  }
}

document.addEventListener("trix-before-initialize", () => {
  window.Trix.config.textAttributes.underline = underline
})

document.addEventListener("trix-initialize", (event) => {
  const group = event.target.toolbarElement.querySelector(".trix-button-group--text-tools")
  if (!group || group.querySelector("[data-trix-attribute='underline']")) return

  const button = document.createElement("button")
  button.type = "button"
  button.className = "trix-button trix-button--icon trix-button--icon-underline"
  button.setAttribute("data-trix-attribute", "underline")
  button.setAttribute("data-trix-key", "u")
  button.title = "Underline"
  button.tabIndex = -1
  button.setAttribute("aria-label", "Underline")

  const italic = group.querySelector("[data-trix-attribute='italic']")
  if (italic) {
    italic.insertAdjacentElement("afterend", button)
  } else {
    group.appendChild(button)
  }
})
