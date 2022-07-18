#' <Add Title>
#'
#' <Add Description>
#'
#' @import htmlwidgets
#'
#' @export
scimvis <- function(r_data, m_data, nhood_sim, width = NULL, height = NULL, elementId = NULL) {

  # forward options using x
  x = list(
    r_data = r_data,
    m_data = m_data,
    nhood_sim = nhood_sim
  )

  # create widget
  htmlwidgets::createWidget(
    name = 'scimvis',
    x,
    width = width,
    height = height,
    package = 'scimvisR',
    elementId = elementId
  )
}

