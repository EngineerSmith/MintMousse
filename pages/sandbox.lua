local ROOT = (...):match("^(.-)[^%.]+%.[^%.]+$") or ""

local socket = require("socket")

local mintmousse = require(ROOT .. "conf")

local log = mintmousse._logger:extend("Pages"):extend("Sandbox")

local sandbox = {
  name = "Sandbox",
}

sandbox.build = function(tab, config)
  mintmousse.batchStart()

  tab
    :addAlert({ size = 5, color = "success", text = "GO GO GO! Sandbox time" })

    :newCard({ size = 5, title = "Accordion Example" })
      :newAccordion()
        :addText({ title = "Bouncy", text = "World"})
        :newContainer()
          :addText({ text = "Deepwithin" })
          :addAlert({ text = "Secret Alert" })
          .back
        .back
      .back

    :newCard({ size = 5, title = "Button & Group" })
      :addButton({ colorOutline = "info", text = "Cyan Button", isCentered = true })
      :addHorizontalRule()
      :newButtonGroup()
        :addButton({ color = "warning", text = "I like the color Yellow" })
        :addButton()
        :addButton({ color = "danger", text = "PRESS ME!" })
        .back
      .back

    :newCard({ size = 5, title = "Card Component Demo" })
      :newCard({ title = "Hello Dave" })
        :addCardHeader({ text = "HEADER" })
        :newCardBody()
          :addCardText({ text = "word word word" })
          :addCardTitle({ text = "title after text?!" })
          :addHorizontalRule()
          :addText({ text = "non card text" })
          .back
        :addCardFooter({ text = "FOOTER! Copyright 1066" })
        .back
      .back

    :newCard({ size = 5, title = "Horizontal Rules" })
      :newContainer()
        :addHorizontalRule()
        :addHorizontalRule({ color = "primary", margin = 4 })
        :addHorizontalRule({ color = "success" })
        .back
      .back

    :newCard({ size = 5, title = "Input" })
      :addTextInput({ placeholder = "Placeholder!" }) -- onEventSubmit; .value
      :addTextInput({ placeholder = "Disabled", isDisabled = true })
      :addTextInput({ value = "Default value!" })
      :addHorizontalRule({ margin = 1 })
      :newRow()
        :addSwitch({ text = "Toggle me!" }) -- onEventToggle; .isChecked
        :addSwitch({ text = "Disabled", isDisabled = true })
        :addSwitch({ text = "Label", isChecked = true }) -- default on
        .back
      .back

    :newCard({ size = 5, title = "List Demo" })
      :newList()
        :addText({ text = "It's like an accordion, but not bouncy" })
        :addText({ text = "A 2nd entry" })
        :newContainer()
          :addCardTitle({ text = "card title" })
          :addCardText({ text = "card text" })
          .back
        .back
      :newList({ isNumbered = true })
        :addText({ text = "We have numbers!!!" })
        :addText({ text = "An actual 2nd entry" })
        :newContainer()
          :newCardBody()
            :addCardHeader({ text = "Header" })
            :addCardFooter({ text = "Footer" })
            .back
          .back
        .back
      .back
    
    :newCard({ size = 5, title = "Row layout \\w Progress Bars" })
      :newRow()
        :addProgressBar({ columnWidth = 5, percentage = 33.3, showLabel = true, isStriped = true, color = "info" })
        :addText({ columnWidth = 2, text = "Middle of the pack", isCentered = true })
        :addProgressBar({ columnWidth = 5, percentage = 66.6, showLabel = true, color = "light" })
        .back
      .back
    
    :newCard({ size = 5, title = "Stacked Progress Bar" })
      :addHorizontalRule({ margin = 1 })
      :newStackedProgressBar()
        :addProgressBar({ percentage = 80, color = "primary", showLabel = true })
        :addProgressBar({ percentage = 80, color = "secondary", showLabel = true })
        :addProgressBar({ percentage = 80, color = "success", showLabel = true })
        :addProgressBar({ percentage = 80, color = "danger", showLabel = true })
        :addProgressBar({ percentage = 80, color = "warning", showLabel = true })
        :addProgressBar({ percentage = 80, color = "info", showLabel = true })
        :addProgressBar({ percentage = 80, color = "light", showLabel = true })
        :addProgressBar({ percentage = 80, color = "dark", showLabel = true })
        .back
      :addHorizontalRule({ margin = 1 })
      :newStackedProgressBar()
        :addProgressBar({ percentage = 80, color = "primary", showLabel = true, isStriped = true })
        :addProgressBar({ percentage = 80, color = "secondary", showLabel = true, isStriped = true })
        :addProgressBar({ percentage = 80, color = "success", showLabel = true, isStriped = true })
        :addProgressBar({ percentage = 80, color = "danger", showLabel = true, isStriped = true })
        :addProgressBar({ percentage = 80, color = "warning", showLabel = true, isStriped = true })
        :addProgressBar({ percentage = 80, color = "info", showLabel = true, isStriped = true })
        :addProgressBar({ percentage = 80, color = "light", showLabel = true, isStriped = true })
        :addProgressBar({ percentage = 80, color = "dark", showLabel = true, isStriped = true })
        .back
      :addHorizontalRule({ margin = 1 })

  mintmousse.batchEnd()
end

return sandbox