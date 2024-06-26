plot_pca_grouped <- function(pcs_df, pca_output, settings, groupingVariable) {
    var_expl_x <- round(100 * pca_output$sdev[as.numeric(gsub("[^0-9]", "", settings$pcaComponentsDisplayX))]^2/sum(pca_output$sdev^2), 1)
    var_expl_y <- round(100 * pca_output$sdev[as.numeric(gsub("[^0-9]", "", settings$pcaComponentsDisplayY))]^2/sum(pca_output$sdev^2), 1)
    labels <- rownames(pca_output$x)

    pcs_df$fill_ <-  as.character(pcs_df[, groupingVariable, drop = TRUE])


    theme_set(eval(parse(text=paste0(settings$theme, "()"))))

    plot  <- ggplot(pcs_df, aes_string(settings$pcaComponentsDisplayX, 
                settings$pcaComponentsDisplayY, 
                fill = 'fill_', 
                colour = 'fill_'
            )) +
            stat_ellipse(geom = "polygon", alpha = 0.1) +
            geom_point() 
            #geom_text(aes(label = labels),  size = 5) +

    if(settings$displayLoadings == TRUE){
        # Extract loadings of the variables
        PCAloadings <- data.frame(Variables = rownames(pca_output$rotation), pca_output$rotation)
        PCAloadings$xend <- PCAloadings[[settings$pcaComponentsDisplayX]]*50
        PCAloadings$yend <- PCAloadings[[settings$pcaComponentsDisplayY]]*50
        plot  <- plot  +
            geom_segment(data = PCAloadings, aes(x = 0, y = 0, xend =  xend, yend = yend,  fill = NULL), colour = "grey30", size=0.40, arrow = arrow(length = unit(1/2, "picas")), color = "black") +
            annotate("text", x = PCAloadings$xend, y = PCAloadings$yend, label = PCAloadings$Variables)

    }

    plot  <- plot  +
        scale_colour_discrete(guide = FALSE) +
        guides(fill = guide_legend(title = "groups")) +
        scale_color_brewer(palette=settings$colorPalette) + 
        theme(text=element_text(size=settings$fontSize), axis.title.x = element_blank(), axis.text.x = element_blank(), axis.ticks.x = element_blank(), legend.position="top")  +
        coord_equal() +
        xlab(paste0(settings$pcaComponentsDisplayX, " (", var_expl_x, "% explained variance)")) +
        ylab(paste0(settings$pcaComponentsDisplayY, " (", var_expl_y, "% explained variance)"))

    return(plot)
}


plot_pca <- function(pcs_df, pca_output, settings) {
    var_expl_x <- round(100 * pca_output$sdev[as.numeric(gsub("[^0-9]", "", settings$pcaComponentsDisplayX))]^2/sum(pca_output$sdev^2), 1)
    var_expl_y <- round(100 * pca_output$sdev[as.numeric(gsub("[^0-9]", "", settings$pcaComponentsDisplayY))]^2/sum(pca_output$sdev^2), 1)
    labels <- rownames(pca_output$x)
    

    theme_set(eval(parse(text=paste0(settings$theme, "()"))))

    # plot without grouping variable
    plot  <-  ggplot(pcs_df, 
                             aes_string(settings$pcaComponentsDisplayX, 
                                        settings$pcaComponentsDisplayY
                             )) +
    
    
    geom_point() + 
    #geom_text(aes(label = labels),  size = 5) +
    scale_fill_brewer(palette=settings$colorPalette) +
    theme(text=element_text(size=settings$fontSize), axis.title.x = element_blank(), axis.text.x = element_blank(), axis.ticks.x = element_blank())  + 
    coord_equal() +
    xlab(paste0(settings$pcaComponentsDisplayX, " (", var_expl_x, "% explained variance)")) +
    ylab(paste0(settings$pcaComponentsDisplayY, " (", var_expl_y, "% explained variance)")) 
    
    return(plot)
    
}

plot_scree <- function(pca_output, settings) {
    

    eig = (pca_output$sdev)^2
    variance <- eig*100/sum(eig)
    cumvar <- paste(round(cumsum(variance),0), "")
    eig_df <- data.frame(eig = eig,
                         PCs = colnames(pca_output$x),
                         cumvar =  cumvar)

    theme_set(eval(parse(text=paste0(settings$theme, "()"))))

    plot  <- ggplot(eig_df, aes(reorder(PCs, -eig), eig)) +
        geom_bar(stat = "identity") +
        geom_text(label = cumvar,
                  vjust=-0.4) +
        scale_fill_brewer(palette=settings$colorPalette) +
        theme(text=element_text(size=settings$fontSize), axis.title.x = element_blank(), axis.text.x = element_blank(), axis.ticks.x = element_blank())  + 
        xlab("PC") +
        ylab("Variances") +
        ylim(0,(max(eig_df$eig) * 1.1))  

    return(plot)
}


# http://www.opensubscriber.com/message/r-help@stat.math.ethz.ch/7315408.html
# KMO Kaiser-Meyer-Olkin Measure of Sampling Adequacy 
kmo_test = function( data_correlation ){ 
    
    X <- data_correlation
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
      test <- 'The KMO test yields a degree of common variance unacceptable for FA.' 
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
