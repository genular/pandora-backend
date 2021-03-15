plot_pca_grouped <- function(pcs_df, pca_output, input, groupingVariable) {
    var_expl_x <- round(100 * pca_output$sdev[as.numeric(gsub("[^0-9]", "", input$pcaComponentsDisplayX))]^2/sum(pca_output$sdev^2), 1)
    var_expl_y <- round(100 * pca_output$sdev[as.numeric(gsub("[^0-9]", "", input$pcaComponentsDisplayY))]^2/sum(pca_output$sdev^2), 1)
    labels <- rownames(pca_output$x)

    pcs_df$fill_ <-  as.character(pcs_df[, groupingVariable, drop = TRUE])

    # Extract loadings of the variables
    PCAloadings <- data.frame(Variables = rownames(pca_output$rotation), pca_output$rotation)
    PCAloadings$xend <- PCAloadings[[input$pcaComponentsDisplayX]]*50
    PCAloadings$yend <- PCAloadings[[input$pcaComponentsDisplayY]]*50

    plot  <- ggplot(pcs_df, aes_string(input$pcaComponentsDisplayX, 
                                          input$pcaComponentsDisplayY, 
                                          fill = 'fill_', 
                                          colour = 'fill_'
                                          )) +
        stat_ellipse(geom = "polygon", alpha = 0.1) +
        geom_point() + 
        #geom_text(aes(label = labels),  size = 5) +
        
        geom_segment(data = PCAloadings, aes(x = 0, y = 0, xend =  xend,
                                             yend = yend, 
                                             fill = NULL), colour = "grey30", size=0.40, arrow = arrow(length = unit(1/2, "picas")), color = "black") +
        annotate("text", x = PCAloadings$xend, y = PCAloadings$yend, label = PCAloadings$Variables) + 

        theme_bw(base_size = 14) +
        scale_colour_discrete(guide = FALSE) +
        guides(fill = guide_legend(title = "groups")) +
        theme(legend.position="top") +
        coord_equal() +
        xlab(paste0(input$pcaComponentsDisplayX, " (", var_expl_x, "% explained variance)")) +
        ylab(paste0(input$pcaComponentsDisplayY, " (", var_expl_y, "% explained variance)")) 

    return(plot)
    
}


plot_pca <- function(pcs_df, pca_output, input) {
    var_expl_x <- round(100 * pca_output$sdev[as.numeric(gsub("[^0-9]", "", input$pcaComponentsDisplayX))]^2/sum(pca_output$sdev^2), 1)
    var_expl_y <- round(100 * pca_output$sdev[as.numeric(gsub("[^0-9]", "", input$pcaComponentsDisplayY))]^2/sum(pca_output$sdev^2), 1)
    labels <- rownames(pca_output$x)
    

    # plot without grouping variable
    plot  <-  ggplot(pcs_df, 
                             aes_string(input$pcaComponentsDisplayX, 
                                        input$pcaComponentsDisplayY
                             )) +
    
    
    geom_point() + 
    #geom_text(aes(label = labels),  size = 5) +
    theme_minimal() +
    scale_fill_brewer(palette="Set1") + 
    coord_equal() +
    xlab(paste0(input$pcaComponentsDisplayX, " (", var_expl_x, "% explained variance)")) +
    ylab(paste0(input$pcaComponentsDisplayY, " (", var_expl_y, "% explained variance)")) 
    
    return(plot)
    
}

plot_scree <- function(pca_output) {
    
    eig = (pca_output$sdev)^2
    variance <- eig*100/sum(eig)
    cumvar <- paste(round(cumsum(variance),0), "")
    eig_df <- data.frame(eig = eig,
                         PCs = colnames(pca_output$x),
                         cumvar =  cumvar)

    plot  <- ggplot(eig_df, aes(reorder(PCs, -eig), eig)) +
        geom_bar(stat = "identity") +
        geom_text(label = cumvar,
                  vjust=-0.4) +
        theme_minimal() +
        scale_fill_brewer(palette="Set1") +
        xlab("PC") +
        ylab("Variances") +
        ylim(0,(max(eig_df$eig) * 1.1))  

    return(plot)
}


# http://www.opensubscriber.com/message/r-help@stat.math.ethz.ch/7315408.html
# KMO Kaiser-Meyer-Olkin Measure of Sampling Adequacy 
kmo_test = function( data ){ 
    

    X <- cor(as.matrix(data)) 
    iX <- MASS::ginv(X) 
    S2 <- diag(diag((iX^-1))) 
    AIS <- S2%*%iX%*%S2                      # anti-image covariance matrix 
    IS <- X+AIS-2*S2                         # image covariance matrix 
    Dai <- sqrt(diag(diag(AIS))) 
    IR <- MASS::ginv(Dai)%*%IS%*%MASS::ginv(Dai)         # image correlation matrix 
    AIR <- MASS::ginv(Dai)%*%AIS%*%MASS::ginv(Dai)       # anti-image correlation matrix 
    a <- apply((AIR - diag(diag(AIR)))^2, 2, sum) 
    AA <- sum(a) 
    b <- apply((X - diag(nrow(X)))^2, 2, sum) 
    BB <- sum(b) 
    MSA <- b/(b+a)                        # indiv. measures of sampling adequacy 
    
    AIR <- AIR-diag(nrow(AIR))+diag(MSA)  # Examine the anti-image of the 
    # correlation matrix. That is the 
    # negative of the partial correlations, 
    # partialling out all other variables. 
    
    kmo <- BB/(AA+BB)                     # overall KMO statistic 
    
    # Reporting the conclusion 
    if (kmo >= 0.00 && kmo < 0.50){ 
      test <- 'The KMO test yields a degree of common variance 
      unacceptable for FA.' 
    } else if (kmo >= 0.50 && kmo < 0.60){ 
      test <- 'The KMO test yields a degree of common variance miserable.' 
    } else if (kmo >= 0.60 && kmo < 0.70){ 
      test <- 'The KMO test yields a degree of common variance mediocre.' 
    } else if (kmo >= 0.70 && kmo < 0.80){ 
      test <- 'The KMO test yields a degree of common variance middling.' 
    } else if (kmo >= 0.80 && kmo < 0.90){ 
      test <- 'The KMO test yields a degree of common variance meritorious.' 
    } else { 
      test <- 'The KMO test yields a degree of common variance marvelous.' 
    } 
    
    ans <- list(  overall = kmo, 
                  report = test, 
                  individual = MSA, 
                  AIS = AIS, 
                  AIR = AIR ) 
    return(ans) 
    
}
