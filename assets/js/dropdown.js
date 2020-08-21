const isInvisible = (element) => {
  return element.classList.contains("invisible")
}

const makeInvisible = (element) => {
  element.classList.add("invisible")
}

const makeVisible = (element) => {
  element.classList.remove("invisible")
}

const dropdownElements = document.getElementsByClassName("dropdown")

Array.from(dropdownElements).forEach(dropdownElement => {
  const buttonElement = dropdownElement.querySelector(".button")
  const menuElement = dropdownElement.querySelector(".menu")

  makeInvisible(menuElement)

  buttonElement.addEventListener("click", e => {
    if (isInvisible(menuElement))
      makeVisible(menuElement)
    else
      makeInvisible(menuElement)
  })

  window.addEventListener("click", e => {
    if (!isInvisible(menuElement) && !buttonElement.contains(e.target))
      makeInvisible(menuElement)
  })
})
