# Download RNA samples attributes from GEO database 

library(tidyverse)
library(rvest)


# create a web scraper function for this purpose
GEO_crawl = function(GSE_id, save = F){
  base_url = "https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc="
  url = str_c(base_url, GSE_id)
  
  html = read_html(url)
  sample_ids = html %>% html_elements("a") %>% html_text2() %>%
    str_extract("GSM\\d+")
  sample_ids = sample_ids[!is.na(sample_ids)]
  
  sample_urls = str_c(base_url, sample_ids)
  
  table = map_dfr(
    sample_urls,
    function(url){
      
      html = read_html(url)
      
      content = html %>% html_elements("td") %>% html_text2()
      content = content[content != ""]
      content = content[content != " "]
      
      start = which(content == "Status")
      end  = which(content == "Platform ID") - 1
      content = content[start:end]
  
      titles = content[seq(content) %% 2 != 0]
      values = content[seq(content) %% 2 == 0]

      tb = tibble(title = titles, value = values)
      tb = tb %>% pivot_wider(id_cols = everything(), names_from = title, values_from = value) %>%
        mutate(sample_id = str_extract(url, "GSM\\d+")) 
      
    }
  )

  table = table %>% select(sample_id, everything())
  
  if(save){
    write_csv(table, str_c(GSE_id, ".csv"))
  }
  else{
    return(table)
  }
}

res = GEO_crawl("GSE208195")


# run GEO_crawl function
walk(
  c("GSE155121",
    "GSE157329",
    "GSE109555",
    "GSE136447",
    "GSE134571",
    "GSE202542",
    "GSE185643",
    "GSE208195",
    "GSE218314",
    "GSE232861",
    "GSE229578",
    "GSE226794",
    "GSE225893"
    ),
  ~ GEO_crawl(.x, save = T)
)
