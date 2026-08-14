local function wrap_selection(open, close)
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")

  local is_multiline = start_line ~= end_line

  if is_multiline then
    return string.format(
      "c%s\n<C-r>\"\n%s<Esc>",
      open,
      close
    )
  end

  return string.format(
    "c%s<C-r>\"%s<Esc>",
    open,
    close
  )
end


vim.keymap.set("x", "{", function()
  return wrap_selection("{", "}")
end, {
  expr = true,
  desc = "Wrap selection with {}",
})

vim.keymap.set("x", "(", function()
  return wrap_selection("(", ")")
end, {
  expr = true,
  desc = "Wrap selection with ()",
})

vim.keymap.set("x", "[", function()
  return wrap_selection("[", "]")
end, {
  expr = true,
  desc = "Wrap selection with []",
})

vim.keymap.set("x", '"', function()
  return wrap_selection('"', '"')
end, {
  expr = true,
  desc = 'Wrap selection with ""',
})

vim.keymap.set("x", "'", function()
  return wrap_selection("'", "'")
end, {
  expr = true,
  desc = "Wrap selection with ''",
})
