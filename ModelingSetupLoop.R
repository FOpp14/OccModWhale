# Setting up a loop for easy-editing of models
# FO 2025

library(dplyr)
library(tidyr)
library(RPresence)
library(lubridate)
library(ggplot2)
library(gridExtra)

source("Config.R")
setwd(project_dir)

# Read in data files =============================

# Read in selection tables metadata
detections <- read.csv("selections_metadata_file.csv")

# Add column for clean recording name
detections$recording <- sub("\\.Table\\.[0-9]+\\.selections\\.csv$", "", detections$Site, ignore.case = TRUE)

View(detections)
str(detections)

unique(detections$Species)
freqs <- table(detections$Species)
freqs

# Change Harmonics typo
indices <- which(detections$Harmonics == "NULL")
detections$Harmonics[indices] <- "NONE"

num_species <- length(unique(detections$Species))


# Read in recordings metadata
recordings <- readxl::read_excel(
  path = recordings_file,
  col_types = recording_col_types)

str(recordings)
recordings$Year <- as.numeric(format(recordings$Date, "%Y")) # change this depending on the variables you are testing!
recordings$DOY <- lubridate::yday(recordings$Date) # change this depending on the variables you are testing!

# order and add recording number and Period
# change this depending on the variables you are testing!
recordings <- recordings %>%
  arrange(Date, StartTime) %>%
  mutate(RecordingNumber = 1:nrow(recordings)) %>%
  mutate(Duration = Duration_sec) %>%
  select(-c(Duration_sec, PercentofRecordingwithSong))

# Periods (number and year ranges) are set in Config.R as period_years
recordings$Period <- NA
for (p in seq_along(period_years)) {
  recordings$Period[recordings$Year %in% period_years[[p]]] <- p
}

recordings$Period <- as.factor(recordings$Period)
str(recordings)
table(recordings$Period)
summary(recordings)
View(recordings)

# Merge datasets ------------------------
df <- merge(
  x = detections,
  y = recordings,
  by.x = 'recording',
  by.y = "FileName") # change depending on what you have called your column for file names in "recordings"

str(df)
head(df)

# make a summary plot - sparse signals
g_raw <- ggplot2::ggplot(df, aes(x = factor(Species), fill = factor(Period))) +
  geom_bar(stat = "count") +
  coord_flip() +
  scale_fill_grey() +
  theme_bw() +
  labs(y = "Total Detections",
       x = "Signal/Species",
       fill = "Period") +
  theme(legend.position="top") +
  theme(axis.text.y = element_blank())

g_raw

# Decide how many surveys your want per period
j = num_surveys

# Each recording is cut into sections of equal length
# Assign the survey to each detection
assign_surveys <- function(duration, signal_time, num_surveys = survey) {
  breaks <- seq(0, duration, length.out = j + 1) # Divide media file into equal parts
  cut(signal_time, breaks = breaks, labels = FALSE, include.lowest = TRUE) # Assign survey
}

# Apply the assign_surveys function to each row in df
df$survey <- mapply(
  FUN = assign_surveys,
  duration = df$Duration,
  signal_time = df$Begin_Time_s,
  num_surveys = j)

# set the factors
df$Tone_Type <- as.factor(df$Tone_Type)
df$Contour <- as.factor(df$Contour)
df$Harmonics <- as.factor(df$Harmonics)

# order by Date and Species for clarity
df <- df[order(df$Date, df$Species), ]
View(df)

# remember that we are substituting species for sites
num_species

# occupancy analysis ============================================

# generate encounter history -----------------
freq_table <- as.data.frame(table(df$Species, df$RecordingNumber, df$survey))
freq_table$Detected <- ifelse(freq_table$Freq >0, yes = 1, no = 0)
names(freq_table) <- c("Species", "Recording", "Survey", "Freq", "Detected")

View(freq_table)

dim(freq_table)
num_species*j*num_recordings

# frequency column is left in for checking
eh <- freq_table %>%
  group_by(Recording, Species, Survey) %>%
  summarise(Detected = sum(Detected, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(
    names_from = c(Survey),  # Create columns for each combination
    values_from = Detected,
    names_sep = "_",
    values_fill = list(Detected = 0)) %>%
  ungroup()

dim(eh)
num_species*num_recordings # change to your number of species
View(eh)

# generate site covariates - related to year and signals ======================
site_covs <- df %>% # Change the following depending on your variables of choice
  group_by(Species)%>% # allows us to do all of the following operations for each species group
  mutate(Mean_Peak_Freq = mean(Peak_Freq_Hz)/peak_frequency_divisor) %>%
  mutate(Max_Peak_Freq = max(Peak_Freq_Hz)/peak_frequency_divisor) %>%
  mutate(Min_Peak_Freq = min(Peak_Freq_Hz)/peak_frequency_divisor) %>%
  mutate(Mean_Duration_s = mean(Duration_s)) %>%
  mutate(Max_Duration_s = max(Duration_s)) %>%
  mutate(Min_Duration_s = min(Duration_s)) %>%
  mutate(Species = as.factor(Species)) %>%
  arrange(Species) %>%
  ungroup() %>%
  select(Species,
         Contour,
         Tone_Type,
         Harmonics,
         Mean_Duration_s,
         Max_Duration_s,
         Min_Duration_s,
         Mean_Peak_Freq,
         Max_Peak_Freq,
         Min_Peak_Freq
  ) %>%
  distinct(Species, .keep_all = TRUE)

# replicate site_covs * num_recordings
site_covs  <- do.call(rbind, replicate(n = nrow(recordings), site_covs, simplify = FALSE))

# add a few columns
site_covs <- site_covs %>%
  # add recording
  mutate(recording = rep(recordings$RecordingNumber, each = num_species)) %>%
  # add year
  mutate(year = rep(recordings$Year, each = num_species)) %>%
  # add period
  mutate(Period = rep(recordings$Period, each = num_species)) %>%
  # arrange
  arrange(recording, Species)

missing_species <- setdiff(unique(detections$Species), unique(df$Species))
missing_species
detections[detections$Species %in% missing_species, c("recording", "Species")]
##

dim(site_covs)
num_species*num_recordings # change to your number of species
str(site_covs)
summary(site_covs)
View(site_covs)

site_covs <- as.data.frame(site_covs)

# generate survey covariates - these related to survey --------------------
names(recordings)
recordings <- as.data.frame(recordings)

survey_covs <- recordings  %>%
  mutate(SST = if (transform_SST) as.numeric(SST/SST_divisor) else SST) %>%
  mutate(DOY = if (transform_DOY) as.numeric(DOY/DOY_divisor) else DOY) %>%
  mutate(Duration = if (transform_Duration) as.numeric(Duration/Duration_divisor) else Duration) %>%
  mutate(Year = Year-2000) %>%
  select(all_of(surv_covariates))

survey_covs <- as.data.frame(survey_covs)

names(survey_covs)
View(survey_covs)

## create a list of survey covariates
survey_repeated <- survey_covs[rep(seq_len(nrow(survey_covs)), each = num_species), ]
dim(survey_repeated)

# turn into a list for pao
survey_covs_list <- switch(
  as.character(j),
  "2" = lapply(survey_repeated, function(x) cbind(x,x)),
  "3" = lapply(survey_repeated, function(x) cbind(x,x,x))
)

str(survey_covs_list)

# add in variable regarding detection on survey2
survey_covs_list$Survey1 <- cbind(
  rep(0, times = num_species * nrow(survey_covs)),
  eh$`1`)

str(survey_covs_list)
lapply(survey_covs_list, FUN = dim)
lapply(survey_covs_list, FUN = head)

View(survey_covs_list$Period)

# message(paste0("The number of survey covs should be # species * # of recordings)
message(num_species*num_recordings) # replace with your number of species)

# create model set for occupancy analysis ========================
names(site_covs)

# occupancy probability
psimodels <- occupancy_models


# probability of detection for a unit issued but not necessarily detected
names(survey_covs_list)
lapply(survey_covs_list, FUN = summary)
pmodels <- detection_models

# create model set (all combinations)
modelset <- expand.grid(
  psi = psimodels,
  p = pmodels)

dim(modelset)
View(modelset)

#==============================================================================

# begin occupancy analysis --------------------------------------------

# create Pao
pao <- createPao(
  data = eh[-c(1,2)],
  unitcov = site_covs,
  survcov = survey_covs_list,
  nsurveyseason = j,
  methods = pao_method
)

model_outputs <- list()

for (k in 1:nrow(modelset)) {
  print(k)

  # run occupancy model; tigers on trails
  mod_k <- occMod(
    model = list(
      as.formula(paste0("psi ~ ", modelset[k, "psi"])),
      as.formula(paste0("p ~ ", modelset[k, "p"]))
      #as.formula("pi ~ 1"),
      #as.formula("theta ~ PRIME"), # prob of local occ. prior to each survey given local presence (theta0, theta1)
      #as.formula("th0pi ~ 1")  # prob of local occupancy prior to 1st survey
    ),
    data = pao,
    modfitboot = NULL,
    type = "so", # "so.cd",  "so.het" "so"
    maxfn = max_function_evaluations)

  # send feedback
  message(mod_k$modname)
  summary(mod_k)

  # add to modeloutputs
  model_outputs[[k]] <- mod_k
  names(model_outputs)[k] <- mod_k$modname

  # pause a few seconds
  gc()
  Sys.sleep(model_pause_seconds)

} #end of model k

str(model_outputs, max.level = 1)
length(model_outputs)




# loop through models and remove any with issues -------------
issues <- data.frame()

for (g in 1:length(model_outputs)) {
  warnings <- model_outputs[[g]]$warnings$conv
  conv <- model_outputs[[g]]$warnings$VC

  issues[g, 'name'] <- model_outputs[[g]]$modname
  issues[g, 'warnings'] <- warnings
  issues[g, 'VC'] <- ifelse(is.null(conv), yes = "No", no = "Yes")
} # end of model g issues

# look at the issues
issues

# remove problematic models with issues  issues$VC == "Yes" |
indices <- which(issues$warnings < convergence_warning_threshold)
if (remove_VC_problem_models) {
  indices <- union(indices, which(issues$VC == "Yes"))
}
View(issues[indices,])

if(length(indices) > 0) {model_outputs <- model_outputs[-indices]}
length(model_outputs)

names(model_outputs)
length(model_outputs)

# create AIC table ------------------
aictable <- createAicTable(
  mod.list = model_outputs,
  use.aicc = TRUE)

View(aictable$table)
names(aictable$table)

# save aic table
mods_to_save <- c(0, cumsum(aictable$table$wgt))
mods_to_save <- which(mods_to_save < model_weight_cutoff)

aic_ms <- aictable$table[, ] %>%
  select(-c(warn.conv, warn.VC, modlike)) %>%
  mutate(across(where(is.numeric), ~ round(.x, 2))) %>%
  tibble::remove_rownames()

aic_ms

write.csv(aic_ms, aic_file)


# read in the top model
topmod_name <- if (is.null(top_model_override)) aictable$table$Model[1] else top_model_override
topmod <- model_outputs[[topmod_name]]
topmod$modname

summary(topmod)
methods(class = class(topmod))


# re-run to obtain goodness of fit ==============
# uses whichever model was selected as topmod above
topmod <- occMod(
  model = model_outputs[[topmod_name]]$model,
  data = pao,
  modfitboot = gof_bootstrap,
  type = occupancy_model_type, # "so.cd", "so.het", "so"
  maxfn = max_function_evaluations)

topmod$gof


# create table of beta coefficients for top models
topmod$beta

modelcoefs <- data.frame()

for (i in 1:1) {

  modname <- aictable$table[i,"Model"]

  pcoefs <- coef(model_outputs[[modname]], "p", prob = 0.95)
  pcoefs <- cbind(model = modname, param = row.names(pcoefs), pcoefs)
  modelcoefs <- rbind(modelcoefs, pcoefs)

  psicoefs <- coef(model_outputs[[modname]], "psi", prob = 0.95)
  psicoefs <- cbind(model = modname, param = row.names(psicoefs), psicoefs)
  modelcoefs <- rbind(modelcoefs, psicoefs)
}

rownames(modelcoefs) <- NULL
modelcoefs <- modelcoefs %>%
  select(-model)  %>%
  mutate(across(where(is.numeric), ~ round(.x, 2)))

View(modelcoefs)

# save as table S2
write.csv(modelcoefs, file = model_coefs_file)

###  GRAPHING ===========================

#  graph species richness ===================================
modAvgpsi <- topmod$real$psi
str(modAvgpsi)
head(modAvgpsi)

# add in covariates
modAvgpsi <- cbind(modAvgpsi, pao$unitcov)
dim(modAvgpsi)
str(modAvgpsi)
head(modAvgpsi)
summary(modAvgpsi)

# add in detected column
modAvgpsi$Detected <- as.numeric(rowSums(eh[3:4]) >= 1)
summary(modAvgpsi)

# estimate "species richness" by period; use derived occupancy
summary_df <- modAvgpsi %>%
  group_by(Species, Period) %>%
  summarise(max_val = max(est, Detected), .groups = "drop")

names(summary_df)
head(summary_df)
summary(summary_df)

psi_richness <- ggplot(summary_df, aes(x = Species, y = max_val, fill = Period)) +
  geom_col() +
  coord_flip() +
  theme_bw() +
  lims(y = c(0, 4)) +
  scale_fill_grey() +
  labs(y = "Signal Richness",
       x = "Signal/Species",
       fill = "Period") +
  theme(legend.position = "top") +
  theme(axis.text.y = element_blank())

g_plots <- gridExtra::grid.arrange(g_raw, psi_richness, nrow = 1, ncol = 2)
ggsave(g_plots , filename = paste0("Figures/Signal_by_Period.png"), dpi = 500)


# graph psi with predict function =================
coef(topmod, "psi")
summary(site_covs)

newdata = expand.grid(
  Mean_Peak_Freq = seq(from = 1, to = 10, by = 1),
  Max_Duration_s = seq(from = 1, to = 9, by = 1),
  Tone_Type = unique(site_covs$Tone_Type),
  Period =  unique(site_covs$Period)
)

# generate predictions
new_predictions <- predict(
  object = topmod,
  newdata = newdata,
  param = 'psi',
  type = "response"
)

# add in covariate data
new_predictions <- cbind(new_predictions, newdata)
head(new_predictions)

# try a graph -
psi_graph <- ggplot(new_predictions,
                    aes(x = Mean_Peak_Freq,
                        y = est,
                        group = Max_Duration_s,
                        color = Max_Duration_s)) +
  geom_line() +
  facet_grid(Period ~ Tone_Type) +
  scale_color_viridis_c() +
  theme_classic() +
  theme(panel.border = element_rect(color = "black", fill = NA, linewidth = 0.8)) +
  labs(y = paste0("Probability of Signal Issuance - ", expression(psi)),
       x = "Mean Peak Frequency",
       color = "Signal Duration (s)")

psi_graph

ggsave(psi_graph, filename = "Figures/psiplots_1.png" , dpi = 500)


# psi ======== graph with real estimates instead of predictions
View(aictable$table)
View(modelcoefs)
names(modAvgpsi)

modAvgpsi <- modAvgpsi %>%
  group_by(Period) %>%
  arrange(Period, Mean_Peak_Freq)

# create the frequency graph
psi_g_freq <- ggplot(modAvgpsi, aes(x = Max_Peak_Freq, y = est, linetype = factor(Period), color = factor(Period))) +
  geom_smooth(linewidth = 2, alpha = 0.2) +
  labs(
    x = "Mean Peak Frequency",
    y = expression(psi),
    color = "Period") +
  guides(linetype = "none") +
  theme_bw() +
  theme(legend.position = "top")

psi_g_freq

# create the signal duration graph
psi_g_duration <- ggplot(modAvgpsi, aes(x = Max_Duration_s, y = est, linetype = factor(Period), color = factor(Period))) +
  geom_smooth(linewidth = 2, alpha = 0.3) +
  guides(linetype = "none") +
  labs(
    x = "Max Duration (S)",
    y = expression(psi),
    color = "Period") +
  theme_bw() +
  theme(legend.position = "top")

psi_g_duration

# create the tone type
plot_df <- modAvgpsi %>%
  group_by(Period, Tone_Type) %>%
  summarise(
    mean_est = mean(est),
    se_est = mean(se),
    .groups = "drop"
  )

psi_tone_type <- ggplot(plot_df, aes(x = Period, y = mean_est, fill = Tone_Type)) +
  geom_col(position = position_dodge(width = .9)) +
  geom_errorbar(
    aes(ymin = mean_est - se_est,
        ymax = mean_est + se_est),
    width = 0.2,
    position = position_dodge(width = .9)
  ) +
  lims(y = c(0,1)) +
  scale_fill_grey() +
  labs(
    x = "Period",
    y = "Average Psi Estimate",
    fill = "Tone Type"
  ) +
  theme_classic() +
  theme(legend.position = "top")

psi_tone_type

# save plots for manuscript
psi_plots <- gridExtra::grid.arrange(psi_g_freq, psi_g_duration, psi_tone_type,
                                     nrow = 1, ncol = 3)
ggsave(psi_plots , filename = paste0("Figures/psiplots.png"), dpi = 500)

# p ---graph with real estimates instead of predictions ----------------
View(aictable$table)

modAvgp <- topmod$real$p

dim(modAvgp)
head(modAvgp)
View(modAvgp)

# add in covariates
scovs <- as.data.frame(do.call(cbind, lapply(survey_covs_list, function(x) as.numeric(x[,1]))))
dim(scovs)
str(scovs)

plot_p <- cbind(modAvgp[1:(num_species*num_recordings),], scovs)

dim(plot_p)
num_recordings*num_species

str(plot_p)
str(modAvgp)

head(plot_p)

p_g <- ggplot(plot_p, aes(x = Duration, y = est, shape = factor(Period), color = factor(Period))) +
  geom_point(size = 4) +
  labs(
    x = "Recording Duration (Hours)",
    y = "Detection Probability (p)",
    color = "Period",
    shape = "Period") +
  scale_fill_grey() +
  geom_errorbar(
    aes(ymin = est-se, ymax = est+se),
    width = 0.02) +
  theme_bw() +
  theme(legend.position = "top") +
  lims(y = c(0, 1))

p_g

ggsave(p_g , filename = paste0("Figures/duration.png"), dpi = 500)


# boxplots - extra material =================================================
boxplotdata1 <- site_covs %>%
  select(where(is.numeric)) %>%
  select(-year) %>%
  pivot_longer(
    cols = everything(),
    names_to = "Variable",
    values_to = "Value"
  )

bp1 <- ggplot(boxplotdata1, aes(x = Variable, y = Value)) +
  geom_boxplot() +
  labs(x = "Signal Variables",
       y = "Value") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  ggtitle("B")

bp1

boxplotdata2 <- survey_covs %>%
  select(where(is.numeric)) %>%
  select(-c(Year, RecordingNumber)) %>%
  pivot_longer(
    cols = everything(),
    names_to = "Variable",
    values_to = "Value"
  )

bp2 <- ggplot(boxplotdata2, aes(x = Variable, y = Value)) +
  geom_boxplot() +
  labs(x = "Survey Variables",
       y = "Value") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  ggtitle("A")

# save boxplot figure
boxplot_figs <- gridExtra::grid.arrange(bp2, bp1, nrow = 1, ncol = 2)
ggsave(boxplot_figs, filename = paste0("Figures/boxplots.png"), dpi = 500)




