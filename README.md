____________________________________________________________________

# Hello and welcome to OccModWhale! 🐋

This repo contains scripts and instructions for using occupancy modeling in R as a framework for distinguishing the effects of sampling limitation from true change in whale song and for identifying key features affecting signal presence and detection over time.

____________________________________________________________________

You can read about our proposed methodology in [Oppenheimer et al. 2026](https://onlinelibrary.wiley.com/doi/10.1111/mms.70237?af=R ).

Before you dive in, we recommend familiarizing yourself with the content using [occupancyTuts](https://besjournals.onlinelibrary.wiley.com/doi/full/10.1111/2041-210X.14285), a tutorial series about occupancy modeling, and [RPresence](https://www.usgs.gov/software/presence), the package we are using for occupancy modeling. 

____________________________________________________________________

### Things You Will Need:

💻 [R](https://www.r-project.org/) downloaded to your machine

📄 _Config.R_ from this github repo

📄 _FormattingData.R_ from this github repo

📄 _ModelingSetupLoop.R_ from this github repo

📊 Your own song unit selection tables from Raven, Audacity, Reaper, etc. - this script uses Raven as default

📊 Your own recordings metadata

____________________________________________________________________

### How to Use OccModWhale (A Step-by-Step Guide):

<details style="display: inline-block;"><summary> 1. Preformat your recordings metadata manually by setting up a descriptive excel document </summary>

<br>
<blockquote>
Your metadata for your recordings, including the variables you want to test through your occupancy models, should include a column for the file name, and one column for each respective variable you are testing. This script wants it as an excel sheet - the default naming convention is Recordings.xlsx.
<br>
<br>
It should look like this...
<br>
<br>
<img width="1636" height="222" alt="Screenshot 2026-09-27 at 9 56 04 PM" src="https://github.com/user-attachments/assets/e723c0c9-6f01-43a9-9971-828f05abe5c4" />
<br>
(example data)
<br>
<br>
...with the variables you are testing substituted for Date, StartTime, Duration_sec, PercentwithSong, Lat, Long, Beaufort, Swell_ft, and SST.
</blockquote>
<br>
</details>

<details style="display: inline-block;"><summary style="display: inline-block;"> 2. Install R from terminal </summary>

<br>
<blockquote>
On Mac:

```
brew install r
R --version # check to make sure it worked, and what version you have - you will need r version 4.3 to run RPresence

# if it's not the correct version, install rig
brew install r-rig

# add the correct version via rig
rig add 4.3
rig list # make sure it installed!
rig default 4.3 # make this version the default

R --version # check again to make sure the correct version of R is in use

```

On Windows:

```
winget install RProject.R
R --version # check to make sure it worked, and what version you have - you will need r version 4.3 to run RPresence

# if it's not the correct version, install rig
winget install r-lib.rig

# add the correct version via rig
rig add 4.3
rig list # make sure it installed!
rig default 4.3 # make this version the default

R --version # check again to make sure the correct version of R is in use

```

Create a new R project for this work!

RECOMMENDED: install [Rstudio](https://posit.co/downloads)
</blockquote>
<br>

</details>

<details style="display: inline-block;"><summary style="display: inline-block;"> 3. Install RPresence </summary>

<br>
<blockquote>

```
install.packages("RPresence")
library(RPresence)
```

</blockquote>
<br>

</details>

<details style="display: inline-block;"><summary style="display: inline-block;"> 4. Open Config.R, FormattingData.R, ModelingSetupLoop.R </summary>

<br>
<blockquote>
Make sure to put them in the same folder as your R project!
</blockquote>
<br>

</details>


<details style="display: inline-block;"><summary style="display: inline-block;"> 5. Establish your desired configurations using Config.R </summary>

<br>
<blockquote>
Descriptions of parameters can be found in the script!
</blockquote>
<br>

</details>


<details style="display: inline-block;"><summary style="display: inline-block;"> 6. Preformat your song unit selections by running FormattingData.R </summary>

<br>
<blockquote>
To identify and distinguish between unit types, we used the system developed by Divna Djokic and Franny Oppenheimer, as described in Oppenheimer 2024 (https://scholarworks.uvm.edu/server/api/core/bitstreams/9ad3f2a6-a87f-416e-97a6-71720fee42ae/content).

The formatting document _FormattingData.R_ expects input in the form of multiple RavenPro selection tables in a single folder. If you are using selection tables from another software (Audacity, Reaper, etc.), you will have to adjust the code accordingly.

Each selection table should have an additional annotation columm labeled “Designation”, into which you should have input your own unique unit label for each selection (ex. “21123”, “A”, “1.2”, “Unit1”). If you are not using the naming conventions as detailed in Oppenheimer 2024, you may have to adjust your process accordingly (as noted in FormattingData.R).

Run _FormattingData.R_ on your selection files. The end product should be a csv file titled “selections_metadata.csv”, with columns formatted exactly as follows if you followed the naming conventions in Oppenheimer 2024:
<br>
<br>
<img width="1636" height="92" alt="Screenshot 2026-09-15 at 5 48 57 PM" src="https://github.com/user-attachments/assets/016e2b25-a5e8-49d8-8041-fa8a4b2d0f71" />
<br>
<br>
With your data included, it should look like this:
<br>
<br>
<img width="1640" height="386" alt="Screenshot 2026-09-27 at 10 00 26 PM" src="https://github.com/user-attachments/assets/a8eb87a2-8239-480f-905a-acd48a649309" />
<br>
<br>
And so on and so forth, with one row for each selection made (from all of the inputted tables combined). 
<br>
<br>
If you did not follow the naming conventions in Oppenheimer 2024 and/or are using alternative variables, your column names may look different. The two columns that will always be the same are "Site", which houses the name of the csv file each selection came from, and "Species", which houses your personal designation for each selection.
</blockquote>
<br>

</details>

<details style="display: inline-block;"><summary style="display: inline-block;"> 7. Run ModelingSetupLoop.R to model and graph your results </summary>

<br>
<blockquote>

After you read in your preformatted metadata for your selections (henceforth called “detections”) and recordings (henceforth called “recordings”)...

<br>

Lines 14-33: formatting for your detections dataframe. You may have to change this formatting depending on how you labeled your selections.

Lines 36-63: formatting for your recordings dataframe. You may have to change this formatting depending on the variables you are testing!

Lines 65-116: merging your dataframe (detections and recordings) into one dataframe, henceforth called “df”. This will be your main dataframe. These lines also include the production of a summary plot (“g_raw”), which details the number of detections of each species within a period for your own visualization.

Lines 120-143: Creating an encounter history (“eh”) out of df.

Lines 145-194: Creating site covariates (“site_covs”) out of df.
	
Lines 196-237: Creating survey covariates (“survey_covs”) out of recordings. Includes adding in a variable regarding detection in survey2 to account for likelihood of presence being skewed in technically-related files.

<br>

<img width="1484" height="834" alt="Screenshot 2026-09-15 at 5 52 43 PM" src="https://github.com/user-attachments/assets/cb735876-5472-4877-844f-d65f58203f87" />

<br>
<br>

Lines 239 to 257: creating model sets for occupancy probability (“psimodels”) and detection probability (“pmodels”)

Lines 261-223: Creating a presence-absence object (“pao”) out of survey_covs

Lines 272-410: Occupancy modeling! Removing models with issues, creating an AIC table and a beta coefficients table.

Lines 411-649: Graphing your results!
</blockquote>
<br>

</details>

____________________________________________________________________

We hope this work is helpful for you and your project! If you have any questions or comments, feel free to reach out at occmodwhale@foppenheimer.com!

🐋 🎶 ❤️


