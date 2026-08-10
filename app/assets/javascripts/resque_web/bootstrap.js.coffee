jQuery ->
  popoverLinks = $("a[rel=popover]")
  tooltipTargets = $(".tooltip, a[rel=tooltip]")

  if $.fn.popover?
    popoverLinks.popover()
  else if window.bootstrap?.Popover?
    popoverLinks.each ->
      bootstrap.Popover.getOrCreateInstance(@)

  if $.fn.tooltip?
    tooltipTargets.tooltip()
  else if window.bootstrap?.Tooltip?
    tooltipTargets.each ->
      bootstrap.Tooltip.getOrCreateInstance(@)

