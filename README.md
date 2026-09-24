____________________________________________________________________

# Hello and welcome to OccModWhale!

This repo contains scripts and instructions for using occupancy modeling in R as a framework for distinguishing the effects of sampling limitation from true song change and for identifying key features affecting signal presence and detection over time.

____________________________________________________________________

You can read about our proposed methodology in [Oppenheimer et al. 2026](https://onlinelibrary.wiley.com/doi/10.1111/mms.70237?af=R ).

Before you dive in, we recommend familiarizing yourself with the content using [occupancyTuts](https://besjournals.onlinelibrary.wiley.com/doi/full/10.1111/2041-210X.14285), a tutorial series about occupancy modeling and RPresence. 

____________________________________________________________________

### Things You Will Need:

- [R](https://www.r-project.org/]) downloaded and installed onto your machine

- The [RPresence package](https://www.usgs.gov/software/presence), which we used in R to build and run our occupancy models, downloaded and installed

- The file _Config.R_ from this github repo

- The file _FormattingData.R_ from this github repo

- The file _ModelingSetupLoop.R_ from this github repo

- Your own song unit selection tables from Raven, Audacity, Reaper, etc. - this script uses Raven as default

- Your own recordings metadata

____________________________________________________________________

### Use Checklist:

☐ Establish your desired configurations using _Config.R_

☐ Preformat your song unit selections using _FormattingData.R_

☐ Preformat your recordings metadata manually by setting up a descriptive excel document

☐ Run _ModelingSetupLoop.R_ to model and graph your results

____________________________________________________________________

### Preformatting Your Selection Tables:

To identify and distinguish between unit types, we used the system developed by Divna Djokic and Franny Oppenheimer, as described in [Oppenheimer 2024](https://scholarworks.uvm.edu/server/api/core/bitstreams/9ad3f2a6-a87f-416e-97a6-71720fee42ae/content).

The formatting document _FormattingData.R_ expects input in the form of multiple RavenPro selection tables in a single folder. If you are using selection tables from another software (Audacity, Reaper, etc.), you will have to adjust the code accordingly.

Each selection table should have an additional annotation columm labeled “Designation”, into which you should have input your own unique unit label for each selection (ex. “21123”, “A”, “1.2”, “Unit1”). If you are not using the naming conventions as detailed in Oppenheimer 2024, you may have to adjust your process accordingly (as noted in FormattingData.R).

Run _FormattingData.R_ on your selection files. The end product should be a csv file titled “selections_metadata.csv”, with columns formatted exactly as follows if you followed the naming conventions in Oppenheimer 2024:

<img width="1636" height="92" alt="Screenshot 2026-09-15 at 5 48 57 PM" src="https://github.com/user-attachments/assets/016e2b25-a5e8-49d8-8041-fa8a4b2d0f71" />

With your data included, it should look like this:

<img width="1634" height="478" alt="Screenshot 2026-09-15 at 5 49 32 PM" src="https://github.com/user-attachments/assets/4847dc2c-940e-41bd-9f91-416e3e07f28e" />

And so on and so forth, with one row for each selection made (from all of the inputted tables combined).

____________________________________________________________________

### Preformatting Your Recordings Metadata:

Your metadata for your recordings, including the variables you want to test through your occupancy models, should include a column for the file name, and one column for each respective variable you are testing. This script wants it as an excel sheet - the default naming convention is Recordings.xlsx.

____________________________________________________________________

### Running ModelingSetupLoop.R, and occupancy modeling!

After you read in your preformatted metadata for your selections (henceforth called “detections”) and recordings (henceforth called “recordings”)

<br>

Lines 14-31: formatting for your detections dataframe. You may have to change this formatting depending on how you labeled your selections.

Lines 34-49: formatting for your recordings dataframe. You may have to change this formatting depending on the variables you are using.

Lines 64-115: merging your dataframe (detections and recordings) into one dataframe, henceforth called “df”. This will be your main dataframe. These lines also include the production of a summary plot (“g_raw”), which details the number of detections of each species within a period.

Lines 88-10:  assign surveys to your recordings depending on the number of surveys you want per period. This creates a pseudo-replication of each recording by splitting it into multiple pieces.

Lines 119-142: Creating an encounter history (“eh”) out of df.

Lines 144-180: Creating site covariates (“site_covs”) out of df.
	
Lines 182-200: Creating survey covariates (“survey_covs”) out of recordings.

Lines 202-223: Creating a presence-absence object (“pao”) out of survey_covs

<br>

<img width="1484" height="834" alt="Screenshot 2026-09-15 at 5 52 43 PM" src="https://github.com/user-attachments/assets/cb735876-5472-4877-844f-d65f58203f87" />

<br>


Lines 211-220: Adding in a variable regarding detection in survey2 to account for likelihood of presence being skewed in technically-related files.

Lines 225-256: creating model sets for occupancy probability (“psimodels”) and detection probability (“pmodels”)

Lines 260-406: Occupancy modeling! Removing models with issues, creating an AIC table and a beta coefficients table.

Lines 408-647: Graphing your results!

____________________________________________________________________

This repository is licensed MIT. Attribution appreciated!
____________________________________________________________________

We hope this repo is helpful for you and your project! If you have any questions or comments, feel free to reach out at occmodwhale@foppenheimer.com!

🐋 🎶 ❤️


