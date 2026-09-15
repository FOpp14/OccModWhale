
## Formatting song selection csv files from RavenPro for use in occupancy model
## 10/5/2024
## FO

# set the path to your files
source("config.R")


# list all files in your folder of selection csvs

filelist <- list.files(path, full.names = TRUE)
filelist



# Create an empty data frame

df <- data.frame()


# create a loop that goes through each file (list files)
# read file into R
# RBind data into new data frame? (and store name of file)


for (i in seq_len(length(filelist))) {

  File <- filelist[i] # grab the file from the folder (full name and path)

  # read in the file, make it into a temporary df
  temp_df <- data.frame(read.table(File, sep = "", header = TRUE, fill = TRUE))

  FileName <- basename(File)

  # IF DELTA, TIME.2, X.a..2, Delta.1, Freq.2, X.Hz..2, Avg, Power, Density, X.dB
  # IF AVG POWER DENSITY(dB FS/Hz), DELETE

  for (j in seq_len(nrow(temp_df))) { # go through each line in the file

    # Assign data to each column
    BeginTime <- temp_df[j,"BeginTime.s."]
    EndTime <- temp_df[j,"EndTime.s."]
    PeakFreq <- temp_df[j,"HighFreq.Hz."]
    Designation <- temp_df[j,"Designation"]

    # Now we need to deep-dive into the designation to reverse-engineer the 5-digit code

    # Separate out the designation to get the info from the name
    DesSep <- as.character(Designation) # make it into a character string
    DesSep <- gsub("(.)", "\\1 ", DesSep) # replace nothing between digits with a space between digits
    DesSep <- strsplit(DesSep, " ")[[1]] # split the string at every space
    DesSep <- as.numeric(DesSep) # turn it back into a numeric

    # Now you can grab each digit
    DesSep1 <- DesSep[1]
    DesSep2 <- DesSep[2]
    DesSep3 <- DesSep[3]
    DesSep4 <- DesSep[4]
    DesSep5 <- DesSep[5]



    # And assign information to each value a digit could be

    Contour <- ifelse(DesSep1 == 1, "UPSWEEP",
                      ifelse(DesSep1 == 2, "DOWNSWEEP",
                             ifelse(DesSep1 == 3, "FLAT",
                                    ifelse(DesSep1 == 4, "ARC",
                                           ifelse(DesSep1 == 5, "USHAPE",
                                                  ifelse(DesSep1 == 6, "FREQVARNT",
                                                         ifelse(DesSep1 == 7, "FREQVARHT",
                                                                ifelse(DesSep1 == 9, "FUZZY",
                                                                       "NULL"))))))))


    Tone_Type <- ifelse(DesSep2 == 1, "TONAL",
                        ifelse(DesSep2 == 2, "PULSED",
                               ifelse(DesSep2 == 3, "MIXED",
                                      ifelse(DesSep2 == 4, "NOISYTONAL",
                                             ifelse(DesSep2 == 5, "RASPY",
                                                    "NULL")))))


    Harmonics <- ifelse(DesSep5 == 1, "DENSE",
                        ifelse(DesSep5 == 2, "SPARSE",
                               ifelse(DesSep5 == 3, "NONE",
                                      "NULL")))


    # Replace any null values with the string "null"

    BeginTime <- ifelse(is.null(BeginTime), "null", BeginTime)
    EndTime <- ifelse(is.null(EndTime), "null", EndTime)
    Duration <- (EndTime - BeginTime)
    PeakFreq <- ifelse(is.null(PeakFreq), "null", PeakFreq)
    Designation <- ifelse(is.null(Designation), "null", Designation)

    # Add this new data into the output dataframe
    df <- rbind(df, data.frame(Path = File,
                               Site = FileName,
                               Begin_Time_s = BeginTime,
                               End_Time_s = EndTime,
                               Contour = Contour,
                               Tone_Type = Tone_Type,
                               Harmonics = Harmonics,
                               Duration_s = Duration,
                               Peak_Freq_Hz = PeakFreq,
                               Species = Designation))

  }

}

View(df)


write.csv(df, file = "selections_metadata_file.csv")

#########
