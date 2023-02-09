
#' Extract top N cells from a similarity matrix.
#'
#' Given a matrix of similarity values, extract the top N columns for each row
#' @export
getTopN <- function(sim_mat, N, margin=1) {
  # Order each row/column
  sim_ordered <- t(apply(sim_mat, margin, sort,decreasing=TRUE, index.return=TRUE))

  # subset top N in each row/column
  sim_topN <- lapply(sim_ordered, function(x) list(sim=as.list(x$x[1:N]),index=x$ix[1:N]))

  # Extract column/row names
  if(margin==1) names(sim_topN) <- rownames(sim_mat)
  else  names(sim_topN) <- colnames(sim_mat)

  return(sim_topN)
}

.checkSCE <- function() {
  if(inherits(data, "SingleCellExperiment")) {
    stop("Data must be an instance of a SingleCellExperiment object.")
  }
}

#' @importFrom SingleCellExperiment reducedDimNames
.checkDimred <- function(data, dimred) {
  # Check dimred option is present
  if(!(dimred %in% reducedDimNames(data))) {
    stop(paste0("Cannot find value", dimred ," in the reducedDim slot."))
  }
}

#' @export
normaliseCoords <- function(coords) {
  out <- apply(coords, 2, function(x){(x-min(x))/(max(x)-min(x))})
  return(out)
}


#' Extract neighbourhood information
#'
#' Extracts metadata and embedding coordinates corresponding to each
#' neighbourhood from a Milo object
#' @importFrom miloR nhoodGraph
#' @importFrom SingleCellExperiment reducedDim
#' @importFrom igraph vertex_attr
#' @export
prepareNhoodData <- function(milo, dimred, colour_by, palette) {

  nhood_graph <- nhoodGraph(milo)

  .checkDimred(milo, dimred)
  dimred <- reducedDim(milo, dimred)[as.numeric(vertex_attr(nhood_graph)$name),]
  dimred <- normaliseCoords(dimred)

  coldata <- as.data.frame(colData(milo)[as.numeric(vertex_attr(nhood_graph)$name), ])
  names(coldata) <- names(colData(milo))

  # TODO: Check colour_by is in coldata
  coldata$colour <- palette[coldata[,colour_by]] #TODO: Add default palette

  df <- data.frame(id = vertex_attr(nhood_graph)$name,
                   x_coord = dimred[,1],
                   y_coord = dimred[,2])

  df <- cbind(df, coldata)
  df <- as.list(df)

  return(df)

}

#' Check that the mapping object actually corresponds to points in a_data and b_data
#' @importFrom miloR nhoods
.checkDistMat <- function(a_data, b_data, dist_mat) {
  # Assumes Milo object for now...
  if(!isTRUE(all.equal(dim(dist_mat), c(ncol(nhoods(a_data)), ncol(nhoods(b_data)))))) {
    stop("dist_mat has incorrect dimensions. Should have dimensions nrow(a_data) by nrow(b_data).")
  }

}

prepareMappings <- function(dist_mat, N_max) {
  top_mappings <- getTopN(dist_mat, N_max)
  names(top_mappings) <- paste0("nhood_",names(top_mappings))
  return(top_mappings)

}



#' Make sure data is in correct format for scimvis
#' e.g.
#' each point has id attribute
#' each point has x_coord and y_coord values
.prepareMilo <- function(a_milo, b_milo, dist_mat, dimred,
                         N_max, colour_by, palette, a_title, b_title) {

  # TODO: Multiple dispatch based on type of a_data, b_data

  a_df <- prepareNhoodData(a_milo, dimred, colour_by = colour_by, palette = palette)
  b_df <- prepareNhoodData(b_milo, dimred, colour_by = colour_by, palette = palette)

  .checkDistMat(a_milo, b_milo, dist_mat)
  mappings <- getTopN(dist_mat, N_max)

  x <- list(
    a_data = list(title = a_title, data = a_df),
    b_data = list(title = b_title, data = b_df),
    mappings = mappings
  )

  return(x)

}



#' Display a scimvis widget.
#'
#' @param dist_mat A matrix of distance/similarity values between points of
#' a_data and b_data.
#'
#' @example
#'
#' scimvis(r_milo, m_milo, nhood_sim, colour_by = "celltype",
#'  palette = scrabbitr::getCelltypeColours())
#'
#'
#' @import htmlwidgets
#' @export
scimvis <- function(a_data, b_data, dist_mat, dimred = "UMAP", N_max = 5,
                    colour_by, palette, a_title = "Dataset A", b_title = "Dataset B",
                    width = NULL, height = NULL, elementId = NULL) {

  x <- .prepareMilo(a_data, b_data, dist_mat, dimred, N_max,
                    colour_by, palette, a_title, b_title)

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



