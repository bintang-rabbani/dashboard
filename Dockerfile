# Gunakan image R dengan shiny server
FROM rocker/shiny:4.2.2

# Install dependencies untuk RPostgres
RUN apt-get update && apt-get install -y \
    libssl-dev libcurl4-openssl-dev libxml2-dev libpq-dev \
  && R -e "install.packages(c('shinydashboard','DBI','RPostgres','tidyverse','plotly','DT','viridis'), repos='https://cloud.r-project.org')" \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Salin semua file ke dalam image
COPY . /srv/shiny-server/app

# Set permission
RUN chown -R shiny:shiny /srv/shiny-server/app

# Expose port shiny
EXPOSE 3838

# Jalankan shiny-server
CMD ["/usr/bin/shiny-server"]
