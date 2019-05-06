
###################################################################
###################################################################
### ForCS output processing 
rm(list = ls())
setwd("C:/Users/cyrdo/Sync/Travail/ECCC/Firewood/UQO/Landis-II")
wwd <- paste(getwd(), Sys.Date(), sep = "/")
dir.create(wwd)
setwd(wwd)

require(ggplot2)
require(dplyr)
require(tidyr)


simArea <- c("MRCOuta", "MRCCentre")
areaNameNew <- c(MRCCentre = "MRC Portneuf - Coniferous",
                 MRCOuta = "MRC Papineau - Hardwoods")
#treatment <- c("Firewood", "CJ", "CPRS")

unitConvFact <- 0.01 ### from gC /m2 to tonnes per ha

###################################################################
### Pools - cell level

df <- dfPercentiles <- list()

for (a in seq_along(simArea)) {

    areaName <- simArea[a]

    # log_BiomassC <- get(load(paste0("../outputsCompiled/log_BiomassC_",
    #                                 simArea, "_", treat, ".RData")))
    # log_Pools <- get(load(paste0("../outputsCompiled/log_Pools_",
    #                              simArea, "_", treat, ".RData")))
    log_Summary <- get(load(paste0("../outputsCompiled/log_Summary_",
                                   areaName, ".RData")))

    ## repair a mistake
    if (areaName == "MRCOuta") {
        log_Summary$initComm <- "temp"
    }
    
    ### pools
    dfTmp <- log_Summary %>%
        filter(variable %in% c("ABio",  "BBio", "TotalDOM")) %>%
        mutate(group = paste(simID, areaName, treatment,
                             landtype, initComm, replicate, variable))



    dfPercentilesTmp <- dfTmp %>%
        group_by(areaName, treatment,
                 initComm, Time, variable) %>%
        summarise(p25 = quantile(value, 0.25),
                  p50 = quantile(value, 0.5),
                  p75 = quantile(value, 0.75),
                  p05 = quantile(value, 0.05),
                  p95 = quantile(value, 0.95),
                  meanVal = mean(value),
                  maxVal = max(value),
                  minVal = min(value))

    df[[a]] <- dfTmp
    dfPercentiles[[a]] <- dfPercentilesTmp
}

df <- do.call("rbind", df)
dfPercentiles <- do.call("rbind", dfPercentiles)

nSims <- length(unique(dfTmp$replicate))*length(unique(dfTmp$landtype))

## renaming initComm for nicer plotting
initCommNewNames <- c(bor = "MRC Portneuf - Coniferous",
                      temp = "MRC Papineau - Hardwoods")
treatNewNames <- c(CPRS = "CPRS (100 yr)",
                   CJ = "CJ (35 yr)",
                   Firewood = "Firewood (35 yr)")
df$initComm <- factor(initCommNewNames[as.character(df$initComm)],
                      levels = initCommNewNames)
dfPercentiles$initComm <- factor(initCommNewNames[as.character(dfPercentiles$initComm)],
                                 levels = initCommNewNames)
df$treatment <- factor(treatNewNames[as.character(df$treatment)],
                       levels = treatNewNames)
dfPercentiles$treatment <- factor(treatNewNames[as.character(dfPercentiles$treatment)],
                                  levels = treatNewNames)



p <- ggplot(df, aes(x = Time, y = value*unitConvFact,
                    colour = variable, fill = variable)) +
    #linetype = tenure, +
    theme_dark() +
    facet_grid(initComm ~ treatment) +
    geom_line(data = dfPercentiles,
              aes(x = Time, y = p50*unitConvFact),
              colour = "black", size  = 0.5, alpha = 1) +
    # geom_line(data = dfPercentiles,
    #           aes(x = Time, y = meanVal*unitConvFact),
    #           size  = 0.5, alpha = 1) +
    geom_ribbon(data = dfPercentiles,
                aes(x = Time, y = NULL, colour = NULL,
                    ymin = p05*unitConvFact, ymax = p95*unitConvFact),
                alpha = 0.25) +
    geom_ribbon(data = dfPercentiles,
                aes(x = Time, y = NULL, colour = NULL,
                    ymin = p25*unitConvFact, ymax = p75*unitConvFact),
                alpha = 0.5) +
    # geom_line(data = filter(df, replicate %in% sample(unique(df$replicate), 1)),
    #           aes(x = Time, y = value*unitConvFact, group = group),
    #           size  = 0.2, alpha = 1, colour = "black") +
    scale_colour_manual(values = c("darkgreen","chocolate2", "coral4" )) +
    scale_fill_manual(values = c("darkgreen","chocolate2", "coral4" )) +
    theme(plot.caption = element_text(size = rel(.75), hjust = 0),
          plot.subtitle = element_text(size = rel(.75))) +
    labs(title = paste0("Summary of aggregated pools"),
         subtitle = paste0("Single-cell simulations - ", nSims, " replicates",
                           "\nMedians are represented with black lines",
                           "\n90% of values are comprised within lightly shaded areas",
                           "\n50% of values are comprised within darkly shaded areas."),
                           #"\nA random simulation is represented in black"),
         x = "",
         y = expression(paste("tonnes C"," ha"^"-1","\n")),
         caption = paste0("ABio : Aboveground biomass stocks.",
                          "\nBBio : Belowground (root) biomass stocks.",
                          "\nTotalDOM : Total dead organic matter and soil stocks. (DOM + SOM)"))

fName <- paste0("pools_Summary_singleCellSims.png")

png(filename= fName,
    width = 10, height = 6, units = "in", res = 600, pointsize=10)

    print(p)

dev.off()

###################################################################
### Fluxes cell - level

simArea <- c("MRCCentre", "MRCOuta")
areaNameNew <- c(MRCCentre = "MRC Portneuf - Coniferous",
                 MRCOuta = "MRC Papineau - Hardwoods")

df <- dfPercentiles <- list()

for (a in seq_along(simArea)) {

    areaName <- simArea[a]

    # log_BiomassC <- get(load(paste0("../outputsCompiled/log_BiomassC_",
    #                                 simArea, "_", treat, ".RData")))
    # log_Pools <- get(load(paste0("../outputsCompiled/log_Pools_",
    #                              simArea, "_", treat, ".RData")))
    log_Summary <- get(load(paste0("../outputsCompiled/log_Summary_",
                                   areaName, ".RData")))

    ### pools
    dfTmp <- log_Summary %>%
        filter(variable %in% c("Turnover",  "NetGrowth", "NPP",
                               "Rh", "NEP")) %>%
        mutate(group = paste(simID, areaName, treatment,
                             initComm, landtype, replicate, variable))



    dfPercentilesTmp <- dfTmp %>%
        group_by(areaName, treatment,
                 initComm,  Time, variable) %>%
        summarise(p25 = quantile(value, 0.25),
                  p50 = quantile(value, 0.5),
                  p75 = quantile(value, 0.75),
                  p05 = quantile(value, 0.05),
                  p95 = quantile(value, 0.95),
                  maxVal = max(value),
                  minVal = min(value))

    df[[a]] <- dfTmp
    dfPercentiles[[a]] <- dfPercentilesTmp
}
df <- do.call("rbind", df) 
dfPercentiles <- do.call("rbind", dfPercentiles)

for (treat in c("CPRS", "CJ", "Firewood")) {
        
    
    if(treat == "CPRS") {
        years <- c(375:460)
        zero <- 399
    } else {
        years <- c(390:460)
        zero <- 414
    }
    
    x <- df %>%
        filter(treatment == treat,
               #simArea == areaName,
               Time %in% years) %>%
        mutate(areaName = factor(areaNameNew[as.character(areaName)], levels = areaNameNew))
    
    xPercentiles <- dfPercentiles %>%
        filter(treatment == treat,
               #simArea == areaName,
               Time %in% years) #%>%
        #mutate(areaName = factor(areaNameNew[as.character(areaName)], levels = areaNameNew))
    xPercentiles$areaName <- factor(areaNameNew[as.character(xPercentiles$areaName)], levels = areaNameNew)
        
    
        
    nSims <- length(unique(dfTmp$replicate))*length(unique(dfTmp$landtype))
    
    
    p <- ggplot(x, aes(x = Time - zero, y = value*unitConvFact)) +
                        #colour = variable, fill = variable)) +
        #linetype = tenure, +
        theme_dark() +
        facet_grid(areaName ~ variable ) +
        geom_hline(yintercept = 0, colour = "grey25", linetype = 2, size = 0.3) +
        geom_vline(xintercept = 0, colour = "grey25", linetype = 2, size = 0.3) +
        geom_line(data = xPercentiles,
                  aes(x = Time - zero, y = p50*unitConvFact),
                  size  = 0.5, alpha = 1, colour = "lightblue") +
        geom_ribbon(data = xPercentiles,
                    aes(x = Time - zero, y = NULL, colour = NULL, 
                        ymin = p05*unitConvFact, ymax = p95*unitConvFact),
                    alpha = 0.25, fill = "lightblue") +
        geom_ribbon(data = xPercentiles,
                    aes(x = Time - zero, y = NULL, colour = NULL,
                        ymin = p25*unitConvFact, ymax = p75*unitConvFact),
                    alpha = 0.5, fill = "lightblue") +
        geom_hline(yintercept = 0, colour = "grey25", linetype = 2, size = 0.3) +
        geom_vline(xintercept = 0, colour = "grey25", linetype = 2, size = 0.3) +
        # geom_line(data = filter(df, replicate %in% sample(unique(df$replicate), 1)),
        #           aes(x = Time, y = value*unitConvFact, group = group),
        #           size  = 0.2, alpha = 1, colour = "black") +
        # scale_colour_manual(values = c("darkgreen","chocolate2", "coral4" )) +
        # scale_fill_manual(values = c("darkgreen","chocolate2", "coral4" )) +
        theme(plot.caption = element_text(size = rel(.7), hjust = 0),
              plot.subtitle = element_text(size = rel(.75))) +
        labs(title = paste0("Summary of global fluxes - Harvest treatment: ",treat),
             subtitle = paste0("Single-cell simulations - ", nSims, " replicates",
                               "\nMedians are represented with blue lines",
                               "\n90% of values are comprised within lightly shaded areas",
                               "\n50% of values are comprised within darkly shaded areas."),
                               #"\nA random simulation is represented in black"),
             x = "Years\n(relative to harvest)\n",
             y = expression(paste("tonnes C"," ha"^"-1", " yr"^"-1", "\n")),
             caption = paste0("Turnover: Annual transfer of biomass (above-and belowground) to dead organic matter and soil pools before disturbances occur",
                              "\nNetGrowth: Change in biomass from growth alone: the difference between the biomass at the beginning and the end of the growth routine in the timestep. This value could be negative as the stand ages and mortality outpaces growth.",
                              "\nNPP : Net Primary Production (includes above and belowground). This includes growth and replacement of litterfall and annual turnover, i.e., the sum of NetGrow and turnover.",
                              "\nRh : Heterotrophic respiration. This is the sum of the “To Air” fluxes through decomposition, not disturbance.",
                              "\nNEP : Net Ecosystem Productivity. NPP minus Rh."
             ))
             
    
    fName <- paste0("fluxes_Summary_singleCellSims_", treat, ".png")
    
    png(filename= fName,
        width = 12, height = 6, units = "in", res = 600, pointsize=10)
    
        print(p)
    
    dev.off()
}

