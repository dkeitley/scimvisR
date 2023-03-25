
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

.getDimRedSCE <- function(data, dimred) {

}


#' Extracts SCE dimred and colData info
#'
#' Extracts metadata and embedding coordinates corresponding to each
#' cell/neighbourhood from a SCE/Milo object
#' @importFrom miloR nhoodGraph
#' @importFrom SingleCellExperiment reducedDim
#' @importFrom igraph vertex_attr
#' @export
prepareDataSCE <- function(data, dimred, colour_by, palette) {

  .checkDimred(data, dimred)
  dimred <- reducedDim(data, dimred)
  coldata <- as.data.frame(colData(data))
  point_id <- colnames(data)

  if(class(data) == "Milo") {
    nhood_graph <- nhoodGraph(data)
    dimred <- dimred[as.numeric(vertex_attr(nhood_graph)$name),]
    coldata <- coldata[as.numeric(vertex_attr(nhood_graph)$name), ]
    point_id <- vertex_attr(nhood_graph)$name
  }

  dimred <- normaliseCoords(dimred)
  names(coldata) <- names(colData(data))

  # Check colour_by is in coldata
  if(!(colour_by %in% colnames(coldata))) {
    stop(paste0(colour_by, " was not found in the colData."))
  }


  if(is.null(palette)) {
    palette <- getDiscretePalette(coldata[,colour_by])
  }

  coldata$colour <- palette[coldata[,colour_by]]

  df <- data.frame(id = point_id,
                   x_coord = dimred[,1],
                   y_coord = dimred[,2])

  df <- cbind(df, coldata)
  df <- as.list(df)

  return(df)

}

#' Check that the mapping object actually corresponds to points in a_data and b_data
#' @importFrom miloR nhoods
.checkDistMat <- function(a_data, b_data, dist_mat) {

  if(class(a_data) == "Milo") {

    if(is.null(rownames(dist_mat))) { rownames(dist_mat) <- unlist(a_data@nhoodIndex) }
    if(is.null(colnames(dist_mat))) { colnames(dist_mat) <- unlist(b_data@nhoodIndex) }

    if(!isTRUE(all.equal(dim(dist_mat), c(ncol(nhoods(a_data)), ncol(nhoods(b_data)))))) {
      stop("dist_mat has incorrect dimensions. Should have dimensions nrow(a_data) by nrow(b_data).")
    }

    if(!all(rownames(dist_mat) == unlist(a_data@nhoodIndex))) {
      stop("Row names of the distance matrix do not match with a_data nhood indices ")
    }

    if(!all(colnames(dist_mat) == unlist(b_data@nhoodIndex))) {
      stop("Column names of the distance matrix do not match with b_data nhood indices. ")
    }
  }

  else if(class(a_data) == "SingleCellExperiment") {

    if(is.null(rownames(dist_mat))) { rownames(dist_mat) <- colnames(a_data) }
    if(is.null(colnames(dist_mat))) { colnames(dist_mat) <- colnames(b_data) }

    if(!isTRUE(all.equal(dim(dist_mat), c(ncol(a_data), ncol(b_data))))) {
      stop("dist_mat has incorrect dimensions. Should have dimensions nrow(a_data) by nrow(b_data).")
    }

    if(!all(rownames(dist_mat) == colnames(a_data))) {
      stop("Row names of the distance matrix do not match with a_data colnames. ")
    }

    if(!all(colnames(dist_mat) == colnames(b_data))) {
      stop("Column names of the distance matrix do not match with b_data colnames. ")
    }

  }

  return(dist_mat)

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
.prepareSCE <- function(a_data, b_data, dist_mat, dimred,
                         N_max, colour_by, palette, a_title, b_title) {

  # Allows for different dimred for each dataset
  if(length(dimred) == 1) { dimred <- rep(dimred, 2)}

  a_df <- prepareDataSCE(a_data, dimred[1], colour_by = colour_by, palette = palette)
  b_df <- prepareDataSCE(b_data, dimred[2], colour_by = colour_by, palette = palette)

  dist_mat <- .checkDistMat(a_data, b_data, dist_mat)
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
#' @examples
#' scimvis(r_milo, m_milo, nhood_sim, colour_by = "celltype",
#' palette = scrabbitr::getCelltypeColours())
#'
#'
#' @import htmlwidgets
#' @export
scimvis <- function(a_data, b_data, dist_mat, dimred = "UMAP", N_max = 5,
                    colour_by, palette = NULL, point_size = 2,
                    a_title = "Dataset A", b_title = "Dataset B",
                    opacity_low = 0.1, width = NULL, height = NULL,
                    elementId = NULL) {


  if(class(a_data)!= class(b_data)) {
    stop("a_data and b_data must be of the same class.")
  }

  else if(class(a_data) == "Milo" | class(a_data) == "SingleCellExperiment") {
    x <- .prepareSCE(a_data, b_data, dist_mat, dimred, N_max,
                      colour_by, palette, a_title, b_title)
  }

  # TODO:
  # else if(class(a_data) == "data.frame") {
  #   .prepareDataFrame(a_data, b_data, dist_mat, dimred, N_max,
  #                     colour_by, palette, a_title, b_title)
  # }


  else {
    stop("a_data and b_data must be a SingleCellExperiment, Milo or data.frame object.")
  }



  x$config <- list(point_size = point_size,
                   opacity_low = opacity_low,
                   point_size_large = 1.5*point_size,
                   stroke_widt = '2')

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



