

.minMax <- function(x, na.rm = TRUE) {
  return((x- min(x)) /(max(x)-min(x)))
}


#' Highlights cells in a dimensionality reduction plot.
#' @export
highlightUMAP <- function(A_sce, dimred, colour_by, subset,
                          palette = NULL, point_size = NULL, point_shape = 16, alpha_low = 0.2, legend_point_size = 6) {


  A_dimred <- data.frame(reducedDim(A_sce, dimred))

  # Attach colData obs
  A_df <- cbind(A_dimred, colData(A_sce)[,colour_by])
  colnames(A_df) <- c("x","y","obs")

  A_subset <- A_df[A_df[,"obs"] %in% subset, ]
  #A_subset$obs <- paste0("A_", A_subset$obs)
  A_other <- A_df[!(A_df[,"obs"] %in% subset), ]

  # Plot mapped cells
  if(is.null(point_size)) { point_size <- nrow(df_plot)*0.000005 }
  p <- ggplot(df_plot, aes(x=x,y=y)) +
    ggrastr::geom_point_rast(data = A_other, color="grey", size=point_size, shape = point_shape, alpha = alpha_low, raster.dpi=300) +
    ggrastr::geom_point_rast(data = A_subset, aes(color=obs), size=point_size, shape = point_shape, raster.dpi=300) +
    guides(color = guide_legend(override.aes = list(size=legend_point_size)))

  if(!is.null(palette)) {
    p <- p + scale_color_manual(values = palette, name = "")
  }

  p <- p +  theme_classic(base_size=14) +
    theme(axis.line = element_blank(), axis.text = element_blank(),
          axis.ticks = element_blank(), axis.title = element_blank())

  return(p)

}


#' Colour cells according to their closest related cell in another dataset.
#' @export
plotMappingsOnRef <- function(A_sce, B_sce, sim_mat, dimred = "UMAP", colour_by = "AO_celltypes",
                              subset_by = "AO_celltypes", subset = c("Hypo-Retina-like region"),
                              colour_sim = FALSE, plot_both = TRUE, offset=c(10,0),
                              palette = NULL, colour_map = "viridis",
                              point_size = NULL, point_shape = 16, alpha_low = 0.2, legend_point_size = 6) {

  # Get A dimred info
  A_dimred <- data.frame(reducedDim(A_sce, dimred))
  A_df <- cbind(A_dimred, colData(A_sce)[,subset_by])
  colnames(A_df) <- c("x","y","obs")

  # Get B obs values
  B_obs <- colData(B_sce)[,colour_by]
  names(B_obs) <- colnames(B_sce)

  # Get max mappings
  sim_subset <- sim_mat[A_sce[[subset_by]] %in% subset,]
  subset_max_sim <- getMaxMappings(sim_subset, 1, long_format=FALSE) # bf-dr
  subset_max_sim <- as.data.frame(subset_max_sim)
  colnames(subset_max_sim) <- c("A_cell", "B_cell", "sim")
  rownames(subset_max_sim) <- subset_max_sim$A_cell

  # Subset obs of interest
  A_subset <- A_df[A_df[,"obs"] %in% subset, ]
  A_other <- A_df[!(A_df[,"obs"] %in% subset), ]

  # Get obs of best mapping cells
  A_subset$best_mapping_obs <- B_obs[subset_max_sim[rownames(A_subset),"B_cell"]]



  # Plot mapped cells
  if(is.null(point_size)) { point_size <- nrow(df_plot)*0.000005 }
  p <- ggplot(A_df, aes(x=x,y=y)) +
    ggrastr::geom_point_rast(data = A_other, color="grey90", size=point_size, shape = point_shape, alpha = alpha_low, raster.dpi=300) +
    ggrastr::geom_point_rast(data = A_subset, aes(color=best_mapping_obs), size=point_size, shape = point_shape, raster.dpi=300)

  if(!is.null(palette)) {
    p <- p + scale_color_manual(values = palette[unique(A_subset$best_mapping_obs)], name = "") +
      guides(color = guide_legend(override.aes = list(size=legend_point_size)))
  }

  p <- p +  theme_classic(base_size=14) +
    theme(axis.line = element_blank(), axis.text = element_blank(),
          axis.ticks = element_blank(), axis.title = element_blank())

  return(p)

}

#' Plot related cells across low-dimensional embeddings
#' @export
plotCellMappings <- function(A_sce, B_sce, sim_mat, dimred = "FA", colour_by = "AO_celltypes", subset_by = "AO_celltypes", subset = c("Hypo-Retina-like region"),
                             colour_sim = FALSE, plot_both = TRUE, offset=c(10,0),
                             palette = NULL, colour_map = "viridis",
                             point_size = NULL, point_shape = 16, alpha_low = 0.2, legend_point_size = 6) {


  # Get dimred coordinates
  if(length(dimred)>1) {
    dimred_A <- dimred[1]
    dimred_B <- dimred[2]
  } else {
    dimred_A <- dimred
    dimred_B <- dimred
  }

  A_dimred <- data.frame(reducedDim(A_sce, dimred_A))
  B_dimred <- data.frame(reducedDim(B_sce, dimred_B))

  # Normalise
  A_dimred <- as.data.frame(apply(A_dimred, 2, .minMax))
  B_dimred <- as.data.frame(apply(B_dimred, 2, .minMax))

  # Add spacing to offset umaps
  if(plot_both) {
    B_dimred[,1] <- B_dimred[,1] + offset[1]
    B_dimred[,2] <- B_dimred[,2] + offset[2]
  }

  # Attach colData obs

  if(length(colour_by)>1) {
    colour_by_A <- colour_by[1]
    colour_by_B <- colour_by[2]
  } else {
    colour_by_A <- colour_by
    colour_by_B <- colour_by
  }

  A_df <- cbind(A_dimred, colData(A_sce)[,colour_by_A])
  colnames(A_df) <- c("x","y","obs")

  B_df <- cbind(B_dimred, colData(B_sce)[,colour_by_B])
  colnames(B_df) <- c("x","y","obs")

  # Get max mappings
  sim_subset <- sim_mat[A_sce[[subset_by]] %in% subset,]
  subset_max_sim <- getMaxMappings(sim_subset, 1, long_format=FALSE) # bf-dr
  colnames(subset_max_sim) <- c("A_cell", "B_cell", "sim")

  # Keep non-zero mappings
  subset_max_sim <- subset_max_sim[subset_max_sim$sim > 0,]

  # Remove duplicates
  subset_max_sim <- aggregate(subset_max_sim$sim,by=list(B_cell=subset_max_sim$B_cell),data=subset_max_sim,FUN=mean)
  rownames(subset_max_sim) <- subset_max_sim$B_cell

  A_subset <- A_df[A_df[,"obs"] %in% subset, ]
  A_subset$sim <- 0
  #A_subset$obs <- paste0("A_", A_subset$obs)
  A_other <- A_df[!(A_df[,"obs"] %in% subset), ]

  B_subset <- B_df[unique(subset_max_sim$B_cell),]
  B_subset$sim <- subset_max_sim[rownames(B_subset), "x"]
  #B_subset$obs <- paste0("B_", B_subset$obs)
  B_other <-  B_df[!(rownames(B_df) %in% rownames(B_subset)),]

  if(!plot_both) {
    df_subset <- B_subset
    df_other <- B_other
    df_plot <- B_df
  } else {
    df_subset <- rbind(A_subset, B_subset)
    df_other <- rbind(A_other,B_other)
    df_plot <- rbind(A_df, B_df)
  }


  # Plot mapped cells
  if(is.null(point_size)) { point_size <- nrow(df_plot)*0.000005 }
  p <- ggplot(df_plot, aes(x=x,y=y)) +
    ggrastr::geom_point_rast(data = df_other, color="grey90", size=point_size, shape = point_shape, alpha = alpha_low, raster.dpi=300)

  if(colour_sim) {
    p <- p + ggrastr::geom_point_rast(data = df_subset, aes(color=sim), size=point_size, shape = point_shape, raster.dpi=300) +
      viridis::scale_color_viridis(option=colour_map)

  } else {
    p <- p + ggrastr::geom_point_rast(data = df_subset, aes(color=obs), size=point_size, shape = point_shape, raster.dpi=300) +
      scale_color_manual(values = palette[unique(df_subset$obs)], name = "")

    if(!is.null(palette)) {
      p <- p + guides(color = guide_legend(override.aes = list(size=legend_point_size)))
    }
  }

  p <- p +  theme_classic(base_size=14) +
    theme(axis.line = element_blank(), axis.text = element_blank(),
          axis.ticks = element_blank(), axis.title = element_blank())


  return(p)

}
