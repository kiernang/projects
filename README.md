# Manitoba Provincial Election - Candidate Campaign Financing
## Intro
In 2017 (2016?) I worked as an RA for one of my professors who I later became colleagues with, and for whom I still consider a friend. Without going into details, the project involved tracking vote shares and funding for all candidates in Manitoba. This includes how much they spent on advertising, how much funding was transferred from the riding association, and how much was transferred from the party.

Manitoba has 57 ridings, of which there are typically 3 candidates running at the bare minimum. In 2019, there were ~ 230 candidates in Manitoba. Data on candidate finances is submitted to Elections Manitoba, where the data is stored in a templated PDF document. When I initially worked on this project I was working for the federal government and had a surplus of free time, and had relatively little technical knowledge of any programming language outside of STATA and Excel. As such, I entered the info by hand. I can't remember if I had a dual monitor set up, but I do remember it becoming tedious after a while. 

Since I've been wanting to figure out how to efficiently parse large numbers of PDF's in a single batch for a while now, I decided to revisit this project and attempt to
create a script that could easily parse through each candidate's disclosure form and store it in a tidy dataset.

All candidate finance data is then matched to candidate vote totals. 
## Data
All data is taken from the Elections Manitoba website. Candidate financial disclosure forms can be found [here](https://www.electionsmanitoba.ca/en/Finance/Candidate_Election_Returns/GE2019). Data on results can be found [here](https://www.electionsmanitoba.ca/en/Results/Elections/2019).
I initially didn't see the summary file... and wrote a for loop to go through each candidates returns. I included that file along with a more streamlined version.

I used a batch downloader extension for Chrome to download all files that fit the final filing format. There are some candidates that do not have final returns, so it is likely that the script/batch download will have to be run again at some point in the future.

## Results
The file scraped all but 2 files successfully. If any of the files have inconsistent formatting the program will be unable to  detect where the information is stored. This was an issue with one file, where it appears that the cell that contains the candidate's name was unrecognized due to the bottom border being a different thickness. In the other case, it appears that the file was saved at a different width and each single page spanned over two pages. 

In the code, there is a line that saves the filename in case of failure, and it should be relatively easy to input by hand from there.

## Forthcoming

Eventually, I would like match the ridings in 2019 (when border boundaries changed, read more about it [here](https://www.electionsmanitoba.ca/en/Resources/Maps)) to the ridings in the previous elections. This is doable by matching polling locations to riding names... I think. There may be some issues when I dig into it. Either way, it would be nice to have a time series.

Another possibility is that I could use census tract / dissemination block data... but I'm not sure how fine of data I can obtain from publicly available files.


