FROM rocker/verse:4.3.1

# Install sistem libs untuk RPostgres & plotly
RUN apt-get update && apt-get install -y libpq-dev && rm -rf /var/lib/apt/lists/*

# Install R packages tambahan
RUN R -e "install.packages(c('RPostgres','plotly','viridis'), repos='https://cloud.r-project.org')"

# Salin kode terakhir
COPY . /srv/shiny-server/app
RUN chown -R shiny:shiny /srv/shiny-server

EXPOSE 3838
CMD [\"/usr/bin/shiny-server\"]
